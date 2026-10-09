package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class GigRequest {

    @NotBlank(message = "Gig title is required")
    @Size(max = 120, message = "Gig title must not exceed 120 characters")
    private String title;

    @NotBlank(message = "Description is required")
    @Size(max = 5000, message = "Description must not exceed 5000 characters")
    private String description;

    @Size(max = 5000, message = "Requirements must not exceed 5000 characters")
    private String requirements;

    @NotNull(message = "Gig category is required")
    private GigCategory category;

    @Size(max = 100, message = "Estimated earnings must not exceed 100 characters")
    private String estimatedEarnings;

    @Size(max = 150, message = "Location must not exceed 150 characters")
    private String location;

    @NotBlank(message = "Company name is required")
    @Size(max = 150, message = "Company name must not exceed 150 characters")
    private String companyName;

    @NotBlank(message = "Company phone number is required")
    @Size(max = 30, message = "Company phone number must not exceed 30 characters")
    private String companyPhoneNumber;

    private LocalDate applicationDeadline;

    private String imageData;
}
