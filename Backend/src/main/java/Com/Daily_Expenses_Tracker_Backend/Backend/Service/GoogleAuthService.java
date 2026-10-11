package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AuthResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Util.JwtUtil;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GoogleAuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppUserDetailsService appUserDetailsService;
    private final JwtUtil jwtUtil;

    @Value("${google.oauth.client-id:}")
    private String googleClientId;

    public AuthResponse login(String idToken) {
        GoogleIdToken.Payload payload = verifyIdToken(idToken);
        String email = payload.getEmail();
        String subject = payload.getSubject();

        if (email == null || email.isBlank() || subject == null || subject.isBlank()
                || !Boolean.TRUE.equals(payload.getEmailVerified())) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Google account email could not be verified."
            );
        }

        UserEntity user = userRepository.findByGoogleSubject(subject)
                .orElseGet(() -> userRepository.findByEmail(email).orElse(null));

        if (user == null) {
            user = createGoogleUser(payload, email, subject);
        } else {
            user.setGoogleSubject(subject);
            user.setIsAccountVerified(true);
            user = userRepository.save(user);
        }

        UserDetails userDetails = appUserDetailsService.loadUserByUsername(user.getEmail());
        return new AuthResponse(user.getEmail(), jwtUtil.generateToken(userDetails));
    }

    private GoogleIdToken.Payload verifyIdToken(String idToken) {
        if (googleClientId == null || googleClientId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Google login is not configured on the server."
            );
        }

        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(),
                    GsonFactory.getDefaultInstance()
            )
                    .setAudience(Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken token = verifier.verify(idToken);
            if (token == null) {
                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Invalid Google ID token."
                );
            }
            return token.getPayload();
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (GeneralSecurityException | IOException | RuntimeException ex) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid Google ID token.",
                    ex
            );
        }
    }

    private UserEntity createGoogleUser(
            GoogleIdToken.Payload payload,
            String email,
            String subject
    ) {
        String name = payload.get("name") instanceof String value && !value.isBlank()
                ? value
                : email.substring(0, email.indexOf('@'));

        String username = resolveUsername(name, email);
        UserEntity user = UserEntity.builder()
                .userId(UUID.randomUUID().toString())
                .googleSubject(subject)
                .name(name)
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                .isAccountVerified(true)
                .verifyOtp(null)
                .verifyOtpExpireAt(0L)
                .resetOtp(null)
                .resetOtpExpiredAt(0L)
                .role(Role.USER)
                .build();

        return userRepository.save(user);
    }

    private String resolveUsername(String name, String email) {
        String base = name.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9._]", "");
        if (base.length() < 3) {
            base = email.substring(0, email.indexOf('@'))
                    .toLowerCase(Locale.ROOT)
                    .replaceAll("[^a-z0-9._]", "");
        }
        if (base.length() < 3) base = "user";
        base = base.substring(0, Math.min(base.length(), 25));

        String username = base;
        int suffix = 1;
        while (userRepository.existsByUsername(username)) {
            String suffixText = String.valueOf(++suffix);
            int baseLength = Math.min(30 - suffixText.length(), base.length());
            username = base.substring(0, baseLength) + suffixText;
        }
        return username;
    }
}
