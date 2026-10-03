package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Value
@Builder
public class BudgetResponse {
    Long id;
    String name;
    BigDecimal amount;
    LocalDate startDate;
    LocalDate endDate;
    Long groupId;
    String groupName;
    String ownerName;
    BigDecimal payableAmount;
    List<String> memberUserIds;
    String proofData;
    String splitPercentages;
    boolean owner;
}