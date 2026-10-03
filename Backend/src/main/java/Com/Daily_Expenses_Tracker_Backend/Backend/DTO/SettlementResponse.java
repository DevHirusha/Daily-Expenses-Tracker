package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;

@Value
@Builder
public class SettlementResponse {
    String payerUserId;
    String payerName;
    BigDecimal amount;
    BigDecimal remainingAmount;
    boolean fullyPaid;
    boolean currentUser;
    String proofData;
}