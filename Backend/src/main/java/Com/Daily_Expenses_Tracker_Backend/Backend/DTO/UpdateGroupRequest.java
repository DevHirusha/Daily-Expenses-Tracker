package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateGroupRequest {

    @NotBlank(message = "Group name is required")
    @Size(max = 80, message = "Group name cannot exceed 80 characters")
    private String name;

    @NotBlank(message = "Group icon is required")
    @Size(max = 40, message = "Group icon is invalid")
    private String icon;
}
