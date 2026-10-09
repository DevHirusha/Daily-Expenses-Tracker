package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AuthRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.AppUserDetailsService;
import Com.Daily_Expenses_Tracker_Backend.Backend.Util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminAuthController {

    private final AuthenticationManager authenticationManager;
    private final AppUserDetailsService appUserDetailsService;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    @PostMapping("/login")
    public ResponseEntity<?> adminLogin(@RequestBody AuthRequest request) {

        // 1. Authenticate email and password
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getEmail(),
                            request.getPassword()
                    )
            );

        } catch (BadCredentialsException ex) {

            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", "Invalid email or password.");

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(error);

        } catch (Exception ex) {

            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", "Authentication failed.");

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(error);
        }

        // 2. Find user
        UserEntity user = userRepository
                .findByEmail(request.getEmail())
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        // 3. Check admin role
        if (user.getRole() != Role.ADMIN && user.getRole() != Role.SUPER_ADMIN) {

            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", "Access denied. Admin only.");

            return ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(error);
        }

        // 4. Generate JWT
        UserDetails userDetails =
                appUserDetailsService.loadUserByUsername(
                        request.getEmail()
                );

        String jwtToken = jwtUtil.generateToken(userDetails);

        // 5. Response
        Map<String, Object> response = new HashMap<>();

        response.put("token", jwtToken);
        response.put("role", user.getRole().name());
        response.put("userId", user.getUserId());
        response.put("name", user.getName());
        response.put("email", user.getEmail());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(
            @CurrentSecurityContext(
                    expression = "authentication?.name"
            ) String email
    ) {

        if (email == null) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(
                            Map.of(
                                    "message",
                                    "Not authenticated"
                            )
                    );
        }

        UserEntity user = userRepository
                .findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        Map<String, Object> response = new HashMap<>();

        response.put("userId", user.getUserId());
        response.put("name", user.getName());
        response.put("email", user.getEmail());
        response.put("role", user.getRole().name());

        return ResponseEntity.ok(response);
    }
}