package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CategoryDetailsResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ExpenseRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ExpenseResponse;

import java.time.LocalDate;
import java.util.List;

public interface ExpenseService {
    List<ExpenseResponse> getExpenses(String email, Long budgetId, Long categoryId, LocalDate start, LocalDate end);
    ExpenseResponse createExpense(String email, Long budgetId, ExpenseRequest request);
    ExpenseResponse updateExpense(String email, Long budgetId, Long expenseId, ExpenseRequest request);
    void deleteExpense(String email, Long budgetId, Long expenseId);
    CategoryDetailsResponse getCategoryDetails(String email, Long budgetId, Long categoryId, String month);
}
