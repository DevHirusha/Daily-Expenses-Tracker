package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class ExpenseRequest {
    @NotNull
    private Long categoryId;
    @NotBlank
    private String name;
    @NotNull
    @DecimalMin("0.01")
    private BigDecimal amount;
    @NotNull
    private LocalDate expenseDate;
    private String merchant;
    private String source;
    private String proofData;
}
