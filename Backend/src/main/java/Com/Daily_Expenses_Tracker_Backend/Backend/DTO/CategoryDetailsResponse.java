package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

import java.util.List;

@Value
@Builder
public class CategoryDetailsResponse {
    BudgetCategoryResponse category;
    List<ExpenseResponse> recentPurchases;
    List<WeeklySpendingResponse> weeklySpending;
}
