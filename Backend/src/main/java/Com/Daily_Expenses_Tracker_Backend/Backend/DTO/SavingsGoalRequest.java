package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class SavingsGoalRequest {
    @NotBlank
    private String name;
    private String type;
    @NotNull
    @DecimalMin("0.01")
    private BigDecimal targetAmount;
    @NotNull
    private LocalDate targetDate;
    @NotNull
    @DecimalMin("0.00")
    private BigDecimal savedAmount = BigDecimal.ZERO;
}
