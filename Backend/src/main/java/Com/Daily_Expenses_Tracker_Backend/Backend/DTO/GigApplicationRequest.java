package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class GigApplicationRequest {

    @NotNull
    private Long gigId;

    @Size(max = 5000)
    private String note;
}
