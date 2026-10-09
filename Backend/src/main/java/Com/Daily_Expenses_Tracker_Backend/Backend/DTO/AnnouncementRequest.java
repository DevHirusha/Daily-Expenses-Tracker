package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AnnouncementRequest {

    @NotBlank(message = "Announcement title is required")
    @Size(max = 160, message = "Announcement title must not exceed 160 characters")
    private String title;

    @NotBlank(message = "Announcement message is required")
    @Size(max = 10000, message = "Announcement message must not exceed 10000 characters")
    private String message;
}
