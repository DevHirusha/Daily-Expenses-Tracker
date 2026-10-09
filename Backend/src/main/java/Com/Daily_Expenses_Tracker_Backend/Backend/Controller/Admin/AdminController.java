package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
public class AdminController {

    private final UserRepository userRepository;

    // Get all users
    @GetMapping("/users")
    public ResponseEntity<List<UserEntity>> getAllUsers() {

        return ResponseEntity.ok(
                userRepository.findAll()
        );
    }

    // Get one user
    @GetMapping("/users/{id}")
    public ResponseEntity<UserEntity> getUser(
            @PathVariable Long id
    ) {

        return userRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(
                        ResponseEntity.notFound().build()
                );
    }

    // Promote USER to ADMIN
    @PutMapping("/users/{id}/promote")
    public ResponseEntity<?> promoteToAdmin(
            @PathVariable Long id
    ) {

        UserEntity user = userRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        user.setRole(Role.ADMIN);

        userRepository.save(user);

        return ResponseEntity.ok(
                "User promoted to ADMIN: " + user.getEmail()
        );
    }

    // Demote ADMIN to USER
    @PutMapping("/users/{id}/demote")
    public ResponseEntity<?> demoteToUser(
            @PathVariable Long id
    ) {

        UserEntity user = userRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        user.setRole(Role.USER);

        userRepository.save(user);

        return ResponseEntity.ok(
                "User demoted to USER: " + user.getEmail()
        );
    }

    // Delete user
    @DeleteMapping("/users/{id}")
    public ResponseEntity<?> deleteUser(
            @PathVariable Long id
    ) {

        userRepository.deleteById(id);

        return ResponseEntity.ok("Deleted");
    }
}