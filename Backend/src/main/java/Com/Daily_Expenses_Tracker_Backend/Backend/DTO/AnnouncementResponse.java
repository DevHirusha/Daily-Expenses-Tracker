package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.AnnouncementEntity;
import lombok.Builder;
import lombok.Value;

import java.time.LocalDateTime;

@Value
@Builder
public class AnnouncementResponse {

    Long id;
    String title;
    String message;
    String createdByUserId;
    String createdByName;
    String createdByEmail;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
    Boolean read;

    public static AnnouncementResponse from(AnnouncementEntity announcement) {
        return AnnouncementResponse.builder()
                .id(announcement.getId())
                .title(announcement.getTitle())
                .message(announcement.getMessage())
                .createdByUserId(announcement.getCreatedByUserId())
                .createdByName(announcement.getCreatedByName())
                .createdByEmail(announcement.getCreatedByEmail())
                .createdAt(announcement.getCreatedAt())
                .updatedAt(announcement.getUpdatedAt())
                .build();
    }

    public static AnnouncementResponse from(AnnouncementEntity announcement, boolean read) {
        return AnnouncementResponse.builder()
                .id(announcement.getId())
                .title(announcement.getTitle())
                .message(announcement.getMessage())
                .createdByUserId(announcement.getCreatedByUserId())
                .createdByName(announcement.getCreatedByName())
                .createdByEmail(announcement.getCreatedByEmail())
                .createdAt(announcement.getCreatedAt())
                .updatedAt(announcement.getUpdatedAt())
                .read(read)
                .build();
    }
}
