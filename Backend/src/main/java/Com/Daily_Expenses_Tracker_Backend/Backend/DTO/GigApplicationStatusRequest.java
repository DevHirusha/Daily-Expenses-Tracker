package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GigApplicationStatusRequest {

    @NotNull
    private GigApplicationStatus status;
}
