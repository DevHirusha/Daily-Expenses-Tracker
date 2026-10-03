package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

@Data
public class CreateSettlementRequest {
    @NotNull
    private BigDecimal amount;
    @NotBlank
    private String proofData;
}