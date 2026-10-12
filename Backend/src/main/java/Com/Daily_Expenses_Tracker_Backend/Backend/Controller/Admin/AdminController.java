package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AdminUserResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AdminUserCreateRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AdminUserUpdateRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.SavingsGoalEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.AnnouncementUserStateRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetCategoryRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetSettlementPaymentRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetSettlementRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.ExpenseRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.FriendListRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.FriendRequestRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigApplicationRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GroupMemberRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GroupRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.SavingsGoalHistoryRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.SavingsGoalRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
public class AdminController {

    private final UserRepository userRepository;
    private final GigApplicationRepository applicationRepository;
    private final AnnouncementUserStateRepository announcementUserStateRepository;
    private final BudgetRepository budgetRepository;
    private final BudgetCategoryRepository budgetCategoryRepository;
    private final BudgetSettlementPaymentRepository settlementPaymentRepository;
    private final BudgetSettlementRepository settlementRepository;
    private final ExpenseRepository expenseRepository;
    private final FriendListRepository friendListRepository;
    private final FriendRequestRepository friendRequestRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final GroupRepository groupRepository;
    private final SavingsGoalHistoryRepository savingsGoalHistoryRepository;
    private final SavingsGoalRepository savingsGoalRepository;
    private final PasswordEncoder passwordEncoder;

    // Get all users
    @GetMapping("/users")
    public ResponseEntity<List<AdminUserResponse>> getAllUsers() {

        return ResponseEntity.ok(
                userRepository.findAll().stream()
                        .map(AdminUserResponse::from)
                        .toList()
        );
    }

    // Get one user
    @GetMapping("/users/{id}")
    public ResponseEntity<AdminUserResponse> getUser(
            @PathVariable Long id
    ) {

        return userRepository.findById(id)
                .map(user -> ResponseEntity.ok(AdminUserResponse.from(user)))
                .orElse(
                        ResponseEntity.notFound().build()
                );
    }

    @PostMapping("/users")
    public ResponseEntity<AdminUserResponse> createUser(
            @Valid @RequestBody AdminUserCreateRequest request,
            Authentication authentication
    ) {
        UserEntity actingUser = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));

        String email = request.getEmail().trim().toLowerCase(Locale.ROOT);
        String username = request.getUsername().trim().toLowerCase(Locale.ROOT);
        Role role = request.getRole() == null ? Role.USER : request.getRole();
        boolean verified = Boolean.TRUE.equals(request.getIsAccountVerified());

        if (userRepository.existsByEmail(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email is already in use");
        }
        if (userRepository.existsByUsername(username)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username is already in use");
        }
        if (actingUser.getRole() != Role.SUPER_ADMIN
                && (role != Role.USER || verified)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can assign user roles or verification status");
        }

        UserEntity newUser = UserEntity.builder()
                .userId(UUID.randomUUID().toString())
                .name(request.getName().trim())
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(request.getPassword()))
                .isAccountVerified(verified)
                .verifyOtp(null)
                .verifyOtpExpireAt(0L)
                .resetOtp(null)
                .resetOtpExpiredAt(0L)
                .role(role)
                .build();

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(AdminUserResponse.from(userRepository.save(newUser)));
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<AdminUserResponse> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody AdminUserUpdateRequest request,
            Authentication authentication
    ) {
        UserEntity user = findUser(id);
        UserEntity actingUser = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));

        String email = request.getEmail().trim().toLowerCase(Locale.ROOT);
        String username = request.getUsername().trim().toLowerCase(Locale.ROOT);

        if (userRepository.existsByEmailAndIdNot(email, id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email is already in use");
        }
        if (userRepository.existsByUsernameAndIdNot(username, id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username is already in use");
        }
        if (request.getRole() != null
                && request.getRole() != user.getRole()
                && actingUser.getRole() != Role.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can change user roles");
        }
        if (request.getIsAccountVerified() != null
                && !Objects.equals(request.getIsAccountVerified(), user.getIsAccountVerified())
                && actingUser.getRole() != Role.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can change user verification status");
        }
        if (user.getRole() == Role.SUPER_ADMIN
                && actingUser.getRole() != Role.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can edit a super admin");
        }

        user.setName(request.getName().trim());
        user.setUsername(username);
        user.setEmail(email);
        if (request.getRole() != null) {
            user.setRole(request.getRole());
        }
        if (request.getIsAccountVerified() != null) {
            user.setIsAccountVerified(request.getIsAccountVerified());
        }
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        return ResponseEntity.ok(AdminUserResponse.from(userRepository.save(user)));
    }

    // Promote USER to ADMIN
    @PutMapping("/users/{id}/promote")
    public ResponseEntity<?> promoteToAdmin(
            @PathVariable Long id,
            Authentication authentication
    ) {
        requireSuperAdmin(authentication);

        UserEntity user = findUser(id);

        user.setRole(Role.ADMIN);

        userRepository.save(user);

        return ResponseEntity.ok(
                "User promoted to ADMIN: " + user.getEmail()
        );
    }

    // Demote ADMIN to USER
    @PutMapping("/users/{id}/demote")
    public ResponseEntity<?> demoteToUser(
            @PathVariable Long id,
            Authentication authentication
    ) {
        requireSuperAdmin(authentication);

        UserEntity user = findUser(id);

        user.setRole(Role.USER);

        userRepository.save(user);

        return ResponseEntity.ok(
                "User demoted to USER: " + user.getEmail()
        );
    }

    // Delete user
    @DeleteMapping("/users/{id}")
    @Transactional
    public ResponseEntity<?> deleteUser(
            @PathVariable Long id,
            Authentication authentication
    ) {
        UserEntity user = findUser(id);
        UserEntity actingUser = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));

        if (user.getId().equals(actingUser.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "You cannot delete your own admin account");
        }
        if (user.getRole() == Role.SUPER_ADMIN && actingUser.getRole() != Role.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can delete a super admin");
        }

        deleteUserData(user);
        userRepository.delete(user);

        return ResponseEntity.ok("Deleted");
    }

    private UserEntity findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
    }

    private void deleteUserData(UserEntity user) {
        announcementUserStateRepository.deleteAllByUserId(user.getUserId());
        applicationRepository.deleteAllByApplicant_Id(user.getId());
        friendListRepository.deleteAllByUser(user);
        friendListRepository.deleteAllByFriend(user);
        friendRequestRepository.deleteAllByRequester(user);
        friendRequestRepository.deleteAllByRecipient(user);
        groupMemberRepository.deleteAllByUser(user);
        settlementPaymentRepository.deleteAllByPayer(user);
        settlementRepository.deleteAllByPayer(user);
        expenseRepository.deleteAllByOwner(user);

        for (SavingsGoalEntity goal : savingsGoalRepository.findByOwnerOrderByTargetDateAsc(user)) {
            savingsGoalHistoryRepository.deleteByGoal(goal);
        }
        savingsGoalRepository.deleteAll(savingsGoalRepository.findByOwnerOrderByTargetDateAsc(user));

        for (GroupEntity group : groupRepository.findByOwnerOrderByCreatedAtDesc(user)) {
            for (BudgetEntity budget : budgetRepository.findByGroup(group)) {
                budget.setGroup(null);
            }
            budgetRepository.flush();
            groupMemberRepository.deleteAllByGroup(group);
            groupRepository.delete(group);
        }

        for (BudgetEntity budget : budgetRepository.findByOwnerOrderByIdDesc(user)) {
            expenseRepository.deleteAllByBudget(budget);
            budgetCategoryRepository.deleteAllByBudget(budget);
            settlementPaymentRepository.deleteAllByBudget(budget);
            settlementRepository.deleteAllByBudget(budget);
            budgetRepository.delete(budget);
        }

        budgetRepository.findSharedByMemberUserId(user.getUserId()).forEach(budget -> {
            if (budget.getMemberUserIds() != null) {
                budget.getMemberUserIds().removeIf(user.getUserId()::equals);
                budgetRepository.save(budget);
            }
        });
    }

    private void requireSuperAdmin(Authentication authentication) {
        UserEntity actingUser = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));

        if (actingUser.getRole() != Role.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can change user roles");
        }
    }
}
