package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import lombok.Builder;
import lombok.Value;

import java.time.LocalDateTime;

@Value
@Builder
public class AdminUserResponse {

    Long id;
    String userId;
    String name;
    String username;
    String email;
    Role role;
    Boolean isAccountVerified;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;

    public static AdminUserResponse from(UserEntity user) {
        return AdminUserResponse.builder()
                .id(user.getId())
                .userId(user.getUserId())
                .name(user.getName())
                .username(user.getUsername())
                .email(user.getEmail())
                .role(user.getRole())
                .isAccountVerified(user.getIsAccountVerified())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
