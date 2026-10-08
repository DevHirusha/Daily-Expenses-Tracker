package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class BudgetCategoryRequest {
    @NotBlank
    private String name;
    @NotNull
    private BigDecimal limitAmount;
    @Min(0)
    @Max(100)
    private Integer warningThreshold = 80;
}
