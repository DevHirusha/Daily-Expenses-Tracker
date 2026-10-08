package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateSavingsGoalSavedRequest {
    @NotNull
    @DecimalMin("0.00")
    private BigDecimal savedAmount;
}
