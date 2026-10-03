package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
public class CreateBudgetRequest {
    @NotBlank
    private String name;
    @NotNull
    private BigDecimal amount;
    private LocalDate startDate;
    private LocalDate endDate;
    private Long groupId;
    private List<String> memberUserIds = List.of();
    private String proofData;
}