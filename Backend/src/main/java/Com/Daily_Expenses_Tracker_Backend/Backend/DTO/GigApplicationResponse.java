package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationStatus;
import lombok.Builder;
import lombok.Value;

import java.time.LocalDateTime;
import java.time.LocalDate;

@Value
@Builder
public class GigApplicationResponse {

    Long id;
    Long gigId;
    String gigTitle;
    String estimatedEarnings;
    String companyName;
    String location;
    LocalDate applicationDeadline;
    String imageData;
    GigApplicationStatus status;
    String note;
    Long applicantId;
    String applicantUserId;
    String applicantName;
    String applicantUsername;
    String applicantEmail;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;

    public static GigApplicationResponse from(GigApplicationEntity application) {
        var gig = application.getGig();
        var applicant = application.getApplicant();
        return GigApplicationResponse.builder()
                .id(application.getId())
                .gigId(gig.getId())
                .gigTitle(gig.getTitle())
                .estimatedEarnings(gig.getEstimatedEarnings())
                .companyName(gig.getCompanyName())
                .location(gig.getLocation())
                .applicationDeadline(gig.getApplicationDeadline())
                .imageData(gig.getImageData())
                .status(application.getStatus())
                .note(application.getNote())
                .applicantId(applicant.getId())
                .applicantUserId(applicant.getUserId())
                .applicantName(applicant.getName())
                .applicantUsername(applicant.getUsername())
                .applicantEmail(applicant.getEmail())
                .createdAt(application.getCreatedAt())
                .updatedAt(application.getUpdatedAt())
                .build();
    }
}
