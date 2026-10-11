package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileUpdateRequest;

public interface ProfileService {

    ProfileResponse createProfile(ProfileRequest request);

    ProfileResponse getProfile(String email);

    ProfileResponse updateProfile(String email, ProfileUpdateRequest request);

    void sendResetOtp(String email);

    void resetPassword(String email, String otp, String newPassword);

    void sendOtp(String email);

    void verifyOtp(String email, String otp);

    String getLoggedInUserId(String email);
}
