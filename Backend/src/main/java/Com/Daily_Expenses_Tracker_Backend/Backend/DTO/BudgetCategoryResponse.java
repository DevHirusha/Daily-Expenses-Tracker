package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;

@Value
@Builder
public class BudgetCategoryResponse {
    Long id;
    Long budgetId;
    String name;
    BigDecimal limitAmount;
    BigDecimal spentAmount;
    BigDecimal remainingAmount;
    BigDecimal overLimitAmount;
    Integer warningThreshold;
    boolean overWarningThreshold;
}
