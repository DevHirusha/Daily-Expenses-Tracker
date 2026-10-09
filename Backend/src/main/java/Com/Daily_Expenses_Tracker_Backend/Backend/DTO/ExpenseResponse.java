package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Value
@Builder
public class ExpenseResponse {
    Long id;
    Long budgetId;
    Long categoryId;
    String categoryName;
    String name;
    BigDecimal amount;
    LocalDate expenseDate;
    String merchant;
    String source;
    String proofData;
    LocalDateTime createdAt;
}
