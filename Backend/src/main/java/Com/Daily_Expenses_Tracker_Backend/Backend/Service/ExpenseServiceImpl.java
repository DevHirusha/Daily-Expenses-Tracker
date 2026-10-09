package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CategoryDetailsResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ExpenseRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ExpenseResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.WeeklySpendingResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetCategoryEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.ExpenseEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetCategoryRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.ExpenseRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ExpenseServiceImpl implements ExpenseService {
    private final BudgetRepository budgetRepository;
    private final BudgetCategoryRepository categoryRepository;
    private final ExpenseRepository expenseRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getExpenses(String email, Long budgetId, Long categoryId, LocalDate start, LocalDate end) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findAccessibleBudget(owner, budgetId);
        LocalDate periodStart = start == null ? defaultStart(budget) : start;
        LocalDate periodEnd = end == null ? defaultEnd(budget, periodStart) : end;
        List<ExpenseEntity> expenses;
        if (categoryId == null) {
            expenses = expenseRepository.findByBudgetAndExpenseDateBetweenOrderByExpenseDateDescIdDesc(budget, periodStart, periodEnd);
        } else {
            BudgetCategoryEntity category = findCategory(budget, categoryId);
            expenses = expenseRepository.findByBudgetAndCategoryAndExpenseDateBetweenOrderByExpenseDateDescIdDesc(budget, category, periodStart, periodEnd);
        }
        return expenses.stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional
    public ExpenseResponse createExpense(String email, Long budgetId, ExpenseRequest request) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        BudgetCategoryEntity category = findCategory(budget, request.getCategoryId());
        ExpenseEntity expense = expenseRepository.save(ExpenseEntity.builder()
                .budget(budget)
                .category(category)
                .owner(owner)
                .name(request.getName().trim())
                .amount(request.getAmount())
                .expenseDate(request.getExpenseDate())
                .merchant(trim(request.getMerchant()))
                .source(trim(request.getSource()))
                .proofData(request.getProofData())
                .build());
        return toResponse(expense);
    }

    @Override
    @Transactional
    public ExpenseResponse updateExpense(String email, Long budgetId, Long expenseId, ExpenseRequest request) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        ExpenseEntity expense = expenseRepository.findByIdAndBudget(expenseId, budget)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Expense not found"));
        BudgetCategoryEntity category = findCategory(budget, request.getCategoryId());
        expense.setCategory(category);
        expense.setName(request.getName().trim());
        expense.setAmount(request.getAmount());
        expense.setExpenseDate(request.getExpenseDate());
        expense.setMerchant(trim(request.getMerchant()));
        expense.setSource(trim(request.getSource()));
        expense.setProofData(request.getProofData());
        return toResponse(expenseRepository.save(expense));
    }

    @Override
    @Transactional
    public void deleteExpense(String email, Long budgetId, Long expenseId) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        ExpenseEntity expense = expenseRepository.findByIdAndBudget(expenseId, budget)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Expense not found"));
        expenseRepository.delete(expense);
    }

    @Override
    @Transactional(readOnly = true)
    public CategoryDetailsResponse getCategoryDetails(String email, Long budgetId, Long categoryId, String month) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        BudgetCategoryEntity category = findCategory(budget, categoryId);
        YearMonth selectedMonth = resolveMonth(budget, month);
        LocalDate start = selectedMonth.atDay(1);
        LocalDate end = selectedMonth.atEndOfMonth();
        List<ExpenseEntity> expenses = expenseRepository
                .findByBudgetAndCategoryAndExpenseDateBetweenOrderByExpenseDateDescIdDesc(budget, category, start, end);
        BigDecimal spent = expenses.stream().map(ExpenseEntity::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal limit = category.getLimitAmount();
        BudgetCategoryResponse categoryResponse = BudgetCategoryResponse.builder()
                .id(category.getId())
                .budgetId(budget.getId())
                .name(category.getName())
                .limitAmount(limit)
                .spentAmount(spent)
                .remainingAmount(limit.subtract(spent).max(BigDecimal.ZERO))
                .overLimitAmount(spent.subtract(limit).max(BigDecimal.ZERO))
                .warningThreshold(category.getWarningThreshold())
                .overWarningThreshold(spent.compareTo(limit.multiply(BigDecimal.valueOf(category.getWarningThreshold())).divide(BigDecimal.valueOf(100))) >= 0)
                .build();
        List<WeeklySpendingResponse> weekly = new ArrayList<>();
        for (int week = 0; week < 4; week++) {
            LocalDate weekStart = start.plusDays(week * 7L);
            LocalDate weekEnd = week == 3 ? end : start.plusDays(week * 7L + 6);
            BigDecimal total = expenses.stream()
                    .filter(expense -> !expense.getExpenseDate().isBefore(weekStart) && !expense.getExpenseDate().isAfter(weekEnd))
                    .map(ExpenseEntity::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            weekly.add(WeeklySpendingResponse.builder().label("W" + (week + 1)).amount(total).build());
        }
        return CategoryDetailsResponse.builder()
                .category(categoryResponse)
                .recentPurchases(expenses.stream().limit(10).map(this::toResponse).toList())
                .weeklySpending(weekly)
                .build();
    }

    private YearMonth resolveMonth(BudgetEntity budget, String month) {
        if (month != null && !month.isBlank()) {
            try {
                return YearMonth.parse(month);
            } catch (RuntimeException error) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Month must use YYYY-MM format");
            }
        }
        return budget.getStartDate() == null ? YearMonth.now() : YearMonth.from(budget.getStartDate());
    }

    private BudgetCategoryEntity findCategory(BudgetEntity budget, Long categoryId) {
        return categoryRepository.findByIdAndBudget(categoryId, budget)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));
    }

    private BudgetEntity findOwnedBudget(UserEntity owner, Long budgetId) {
        BudgetEntity budget = budgetRepository.findById(budgetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Budget not found"));
        if (!budget.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the budget owner can manage expenses");
        }
        return budget;
    }

    private BudgetEntity findAccessibleBudget(UserEntity viewer, Long budgetId) {
        BudgetEntity budget = budgetRepository.findById(budgetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Budget not found"));
        if (!budget.getOwner().getId().equals(viewer.getId())
                && !budget.getMemberUserIds().contains(viewer.getUserId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not have access to this budget");
        }
        return budget;
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    private LocalDate defaultStart(BudgetEntity budget) {
        return budget.getStartDate() == null ? LocalDate.now().withDayOfMonth(1) : budget.getStartDate();
    }

    private LocalDate defaultEnd(BudgetEntity budget, LocalDate start) {
        return budget.getEndDate() == null ? start.withDayOfMonth(start.lengthOfMonth()) : budget.getEndDate();
    }

    private String trim(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private ExpenseResponse toResponse(ExpenseEntity expense) {
        return ExpenseResponse.builder()
                .id(expense.getId())
                .budgetId(expense.getBudget().getId())
                .categoryId(expense.getCategory().getId())
                .categoryName(expense.getCategory().getName())
                .name(expense.getName())
                .amount(expense.getAmount())
                .expenseDate(expense.getExpenseDate())
                .merchant(expense.getMerchant())
                .source(expense.getSource())
                .proofData(expense.getProofData())
                .createdAt(expense.getCreatedAt())
                .build();
    }
}
