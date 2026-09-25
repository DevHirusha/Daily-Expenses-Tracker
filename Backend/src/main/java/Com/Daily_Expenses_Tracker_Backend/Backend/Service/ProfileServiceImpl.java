package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
public class ProfileServiceImpl implements ProfileService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    @Override
    public ProfileResponse createProfile(ProfileRequest request) {
        UserEntity newProfile = convertToUserEntity(request);
        if (!userRepository.existsByEmail(request.getEmail())) {
            newProfile = userRepository.save(newProfile);
            return convertToProfileResponse(newProfile);
        }
        throw new ResponseStatusException(HttpStatus.CONFLICT, "Email Already Exists");
    }

    @Override
    public ProfileResponse getProfile(String email) {
        UserEntity existingUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found " + email));
        return convertToProfileResponse(existingUser);
    }

    // Forgot Password / Reset Password process.
    @Override
    public void sendResetOtp(String email) {
        UserEntity existingEntity = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found " + email));

        // Generating a random 6-digit OTP
        String otp = String.valueOf(ThreadLocalRandom.current().nextInt(100000, 1000000));

        // Calculate expiry time (current time + 10 minutes in milliseconds)
        long expiryTime = System.currentTimeMillis() + (10 * 60 * 1000);

        // update the profile/user
        existingEntity.setResetOtp(otp);
        existingEntity.setResetOtpExpiredAt(expiryTime);

        // save into the database
        userRepository.save(existingEntity);

        try {
            emailService.sendResetOtpEmail(existingEntity.getEmail(), otp);
        } catch (Exception ex) {
            throw new RuntimeException("Failed to send password reset OTP. Please try again later.", ex);
        }

    }

    @Override
    public void resetPassword(String email, String otp, String newPassword) {

        UserEntity existingUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found " + email));

        // Validate OTP
        if (existingUser.getResetOtp() == null ||
                !existingUser.getResetOtp().equals(otp)) {

            throw new RuntimeException(
                    "Invalid OTP. Please check your email and try again.");
        }

        // Validate OTP expiration
        if (existingUser.getResetOtpExpiredAt() < System.currentTimeMillis()) {

            throw new RuntimeException(
                    "The OTP has expired. Please request a new OTP.");
        }

        // Update password
        existingUser.setPassword(
                passwordEncoder.encode(newPassword));

        // Clear OTP after successful password reset
        existingUser.setResetOtp(null);
        existingUser.setResetOtpExpiredAt(0L);

        userRepository.save(existingUser);
    }

    // If sendOtp() is for account/email verification
    @Override
    public void sendOtp(String email) {

        UserEntity existingUser = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new UsernameNotFoundException("User not found: " + email)
                );

        if (Boolean.TRUE.equals(existingUser.getIsAccountVerified())) {
            return;
        }

        // Generate 6-digit OTP
        String otp = String.valueOf(
                ThreadLocalRandom.current().nextInt(100000, 1000000)
        );

        // OTP expires after 24 hours
        long expiryTime = System.currentTimeMillis()
                + (24 * 60 * 60 * 1000);

        // Save OTP
        existingUser.setVerifyOtp(otp);
        existingUser.setVerifyOtpExpireAt(expiryTime);

        userRepository.save(existingUser);

        // Send verification email
        try {
            emailService.sendOtpEmail(
                    existingUser.getEmail(),
                    otp
            );
        } catch (Exception ex) {
            throw new RuntimeException(
                    "Failed to send verification OTP. Please try again later.",
                    ex
            );
        }
    }

    @Override
    public String getLoggedInUserId(String email) {
        UserEntity existingUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found :" + email));

        return existingUser.getUserId();
    }

    private ProfileResponse convertToProfileResponse(UserEntity newProfile) {
        return ProfileResponse.builder()
                .name(newProfile.getName())
                .email(newProfile.getEmail())
                .userId(newProfile.getUserId())
                .isAccountVerified(newProfile.getIsAccountVerified())
                .build();
    }

    private UserEntity convertToUserEntity(ProfileRequest request) {
        return UserEntity.builder()
                .email(request.getEmail())
                .userId(UUID.randomUUID().toString())
                .name(request.getName())
                .password(passwordEncoder.encode(request.getPassword()))
                .isAccountVerified(false)
                .resetOtpExpiredAt(0L)
                .verifyOtp(null)
                .verifyOtpExpireAt(0L)
                .resetOtp(null)
                .build();
    }
}
