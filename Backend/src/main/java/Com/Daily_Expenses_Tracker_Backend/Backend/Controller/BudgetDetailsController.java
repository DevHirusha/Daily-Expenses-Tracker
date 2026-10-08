package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CategoryDetailsResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ExpenseRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ExpenseResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.BudgetCategoryService;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.ExpenseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1.0/budgets")
public class BudgetDetailsController {
    private final BudgetCategoryService categoryService;
    private final ExpenseService expenseService;

    @GetMapping("/{budgetId}/categories")
    public List<BudgetCategoryResponse> getCategories(
            @PathVariable Long budgetId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return categoryService.getCategories(email, budgetId);
    }

    @PostMapping("/{budgetId}/categories")
    public BudgetCategoryResponse createCategory(
            @PathVariable Long budgetId,
            @Valid @RequestBody BudgetCategoryRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return categoryService.createCategory(email, budgetId, request);
    }

    @PutMapping("/{budgetId}/categories/{categoryId}")
    public BudgetCategoryResponse updateCategory(
            @PathVariable Long budgetId,
            @PathVariable Long categoryId,
            @Valid @RequestBody BudgetCategoryRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return categoryService.updateCategory(email, budgetId, categoryId, request);
    }

    @DeleteMapping("/{budgetId}/categories/{categoryId}")
    public void deleteCategory(
            @PathVariable Long budgetId,
            @PathVariable Long categoryId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        categoryService.deleteCategory(email, budgetId, categoryId);
    }

    @GetMapping("/{budgetId}/expenses")
    public List<ExpenseResponse> getExpenses(
            @PathVariable Long budgetId,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) LocalDate start,
            @RequestParam(required = false) LocalDate end,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return expenseService.getExpenses(email, budgetId, categoryId, start, end);
    }

    @PostMapping("/{budgetId}/expenses")
    public ExpenseResponse createExpense(
            @PathVariable Long budgetId,
            @Valid @RequestBody ExpenseRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return expenseService.createExpense(email, budgetId, request);
    }

    @PutMapping("/{budgetId}/expenses/{expenseId}")
    public ExpenseResponse updateExpense(
            @PathVariable Long budgetId,
            @PathVariable Long expenseId,
            @Valid @RequestBody ExpenseRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return expenseService.updateExpense(email, budgetId, expenseId, request);
    }

    @DeleteMapping("/{budgetId}/expenses/{expenseId}")
    public void deleteExpense(
            @PathVariable Long budgetId,
            @PathVariable Long expenseId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        expenseService.deleteExpense(email, budgetId, expenseId);
    }

    @GetMapping("/{budgetId}/categories/{categoryId}/details")
    public CategoryDetailsResponse getCategoryDetails(
            @PathVariable Long budgetId,
            @PathVariable Long categoryId,
            @RequestParam(required = false) String month,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return expenseService.getCategoryDetails(email, budgetId, categoryId, month);
    }
}
