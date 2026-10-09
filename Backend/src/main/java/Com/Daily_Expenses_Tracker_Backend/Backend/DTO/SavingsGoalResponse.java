package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.LocalDate;

@Value
@Builder
public class SavingsGoalResponse {
    Long id;
    String name;
    String type;
    BigDecimal targetAmount;
    LocalDate targetDate;
    BigDecimal savedAmount;
    BigDecimal progressPercentage;
    String status;
}
