package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AdminUserResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AdminUserCreateRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AdminUserUpdateRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
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

        userRepository.delete(user);

        return ResponseEntity.ok("Deleted");
    }

    private UserEntity findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
    }

    private void requireSuperAdmin(Authentication authentication) {
        UserEntity actingUser = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));

        if (actingUser.getRole() != Role.SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only a super admin can change user roles");
        }
    }
}
