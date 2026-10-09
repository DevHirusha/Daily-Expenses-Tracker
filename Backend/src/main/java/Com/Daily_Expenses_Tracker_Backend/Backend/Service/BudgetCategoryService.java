package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryResponse;

import java.util.List;

public interface BudgetCategoryService {
    List<BudgetCategoryResponse> getCategories(String email, Long budgetId);
    BudgetCategoryResponse createCategory(String email, Long budgetId, BudgetCategoryRequest request);
    BudgetCategoryResponse updateCategory(String email, Long budgetId, Long categoryId, BudgetCategoryRequest request);
    void deleteCategory(String email, Long budgetId, Long categoryId);
}
