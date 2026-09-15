package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProfileServiceImpl implements  ProfileService{

     private final UserRepository userRepository;


    @Override
    public ProfileResponse createProfile(ProfileRequest request) {
        UserEntity newProfile = convertToUserEntity(request);
        newProfile = userRepository.save(newProfile);
        return convertToProfileResponse(newProfile);
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
                .password(request.getPassword())
                .isAccountVerified(false)
                .resetOtpExpiredAt(0L)
                .verifyOtp(null)
                .verifyOtpExpireAt(0)
                .resetOtp(null)
                .build();
    }
}
