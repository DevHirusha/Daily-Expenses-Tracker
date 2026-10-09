package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigCategory;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigEntity;
import lombok.Builder;
import lombok.Value;

import java.time.LocalDateTime;

@Value
@Builder
public class GigResponse {

    Long id;
    String title;
    String description;
    String requirements;
    GigCategory category;
    String estimatedEarnings;
    String location;
    String companyName;
    String companyPhoneNumber;
    String imageData;
    String createdByUserId;
    String createdByName;
    String createdByEmail;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;

    public static GigResponse from(GigEntity gig) {
        return GigResponse.builder()
                .id(gig.getId())
                .title(gig.getTitle())
                .description(gig.getDescription())
                .requirements(gig.getRequirements())
                .category(gig.getCategory())
                .estimatedEarnings(gig.getEstimatedEarnings())
                .location(gig.getLocation())
                .companyName(gig.getCompanyName())
                .companyPhoneNumber(gig.getCompanyPhoneNumber())
                .imageData(gig.getImageData())
                .createdByUserId(gig.getCreatedByUserId())
                .createdByName(gig.getCreatedByName())
                .createdByEmail(gig.getCreatedByEmail())
                .createdAt(gig.getCreatedAt())
                .updatedAt(gig.getUpdatedAt())
                .build();
    }
}
