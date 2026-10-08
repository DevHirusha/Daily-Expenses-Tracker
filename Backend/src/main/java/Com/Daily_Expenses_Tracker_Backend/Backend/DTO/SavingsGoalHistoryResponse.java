package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Value
@Builder
public class SavingsGoalHistoryResponse {
    Long id;
    BigDecimal amount;
    BigDecimal balanceAfter;
    String entryType;
    LocalDateTime savedAt;
}
