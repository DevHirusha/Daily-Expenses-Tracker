package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class GigApplicationUpdateRequest {

    @Size(max = 5000)
    private String note;
}
