package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class UpdateBudgetRequest {
    @NotBlank
    private String name;
    @NotNull
    private BigDecimal amount;
    private LocalDate startDate;
    private LocalDate endDate;
}
