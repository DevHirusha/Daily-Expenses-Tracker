package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Data;

import java.util.Map;

@Data
public class UpdateBudgetSplitRequest {
    private Map<String, Double> percentages;
    private Map<String, Double> amounts;
}