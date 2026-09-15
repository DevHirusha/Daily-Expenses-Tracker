package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AuthRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationManager authenticationManager;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody AuthRequest request) {

        try {

            authenticate(request.getEmail(), request.getPassword());

            Map<String, Object> response = new HashMap<>();
            response.put("error", false);
            response.put("message", "Login successful.");

            return ResponseEntity
                    .status(HttpStatus.OK)
                    .body(response);

        } catch (BadCredentialsException ex) {

            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", "Invalid email or password.");

            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(error);

        } catch (DisabledException ex) {

            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", "Your account has been disabled.");

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(error);

        } catch (Exception ex) {

            Map<String, Object> error = new HashMap<>();
            error.put("error", true);
            error.put("message", "Authentication failed. Please try again later.");

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(error);
        }
    }

    private void authenticate(String email, String password) {

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        email,
                        password));
    }
}