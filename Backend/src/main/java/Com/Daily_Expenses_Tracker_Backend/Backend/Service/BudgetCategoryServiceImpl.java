package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetCategoryResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetCategoryEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
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
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BudgetCategoryServiceImpl implements BudgetCategoryService {
    private static final List<DefaultCategory> DEFAULTS = List.of(
            new DefaultCategory("Groceries", "20000"),
            new DefaultCategory("Transport", "8000"),
            new DefaultCategory("Eating out", "9000"),
            new DefaultCategory("Bills", "15000"));

    private final BudgetRepository budgetRepository;
    private final BudgetCategoryRepository categoryRepository;
    private final ExpenseRepository expenseRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public List<BudgetCategoryResponse> getCategories(String email, Long budgetId) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        seedDefaultsIfNeeded(budget);
        return categoryRepository.findByBudgetOrderByIdAsc(budget).stream()
                .map(category -> toResponse(category, budget))
                .toList();
    }

    @Override
    @Transactional
    public BudgetCategoryResponse createCategory(String email, Long budgetId, BudgetCategoryRequest request) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        String name = request.getName().trim();
        if (categoryRepository.findByBudgetAndNameIgnoreCase(budget, name).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Category already exists");
        }
        BudgetCategoryEntity category = categoryRepository.save(BudgetCategoryEntity.builder()
                .budget(budget)
                .name(name)
                .limitAmount(request.getLimitAmount())
                .warningThreshold(request.getWarningThreshold() == null ? 80 : request.getWarningThreshold())
                .build());
        return toResponse(category, budget);
    }

    @Override
    @Transactional
    public BudgetCategoryResponse updateCategory(String email, Long budgetId, Long categoryId, BudgetCategoryRequest request) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        BudgetCategoryEntity category = findCategory(budget, categoryId);
        String name = request.getName().trim();
        categoryRepository.findByBudgetAndNameIgnoreCase(budget, name)
                .filter(existing -> !existing.getId().equals(categoryId))
                .ifPresent(existing -> {
                    throw new ResponseStatusException(HttpStatus.CONFLICT, "Category already exists");
                });
        category.setName(name);
        category.setLimitAmount(request.getLimitAmount());
        category.setWarningThreshold(request.getWarningThreshold() == null ? 80 : request.getWarningThreshold());
        return toResponse(categoryRepository.save(category), budget);
    }

    @Override
    @Transactional
    public void deleteCategory(String email, Long budgetId, Long categoryId) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findOwnedBudget(owner, budgetId);
        BudgetCategoryEntity category = findCategory(budget, categoryId);
        if (expenseRepository.countByCategory(category) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Category has expenses and cannot be deleted");
        }
        categoryRepository.delete(category);
    }

    private void seedDefaultsIfNeeded(BudgetEntity budget) {
        if (!categoryRepository.findByBudgetOrderByIdAsc(budget).isEmpty()) return;
        List<BudgetCategoryEntity> categories = new ArrayList<>();
        for (DefaultCategory defaultCategory : DEFAULTS) {
            categories.add(BudgetCategoryEntity.builder()
                    .budget(budget)
                    .name(defaultCategory.name())
                    .limitAmount(new BigDecimal(defaultCategory.limit()))
                    .warningThreshold(80)
                    .build());
        }
        categoryRepository.saveAll(categories);
    }

    private BudgetCategoryResponse toResponse(BudgetCategoryEntity category, BudgetEntity budget) {
        LocalDate start = budget.getStartDate() == null
                ? LocalDate.now().withDayOfMonth(1)
                : budget.getStartDate();
        LocalDate end = budget.getEndDate() == null
                ? start.withDayOfMonth(start.lengthOfMonth())
                : budget.getEndDate();
        BigDecimal spent = expenseRepository.sumAmount(budget, category, start, end);
        if (spent == null) spent = BigDecimal.ZERO;
        BigDecimal remaining = category.getLimitAmount().subtract(spent).max(BigDecimal.ZERO);
        BigDecimal overLimit = spent.subtract(category.getLimitAmount()).max(BigDecimal.ZERO);
        BigDecimal warningAmount = category.getLimitAmount()
                .multiply(BigDecimal.valueOf(category.getWarningThreshold()))
                .divide(BigDecimal.valueOf(100));
        return BudgetCategoryResponse.builder()
                .id(category.getId())
                .budgetId(budget.getId())
                .name(category.getName())
                .limitAmount(category.getLimitAmount())
                .spentAmount(spent)
                .remainingAmount(remaining)
                .overLimitAmount(overLimit)
                .warningThreshold(category.getWarningThreshold())
                .overWarningThreshold(spent.compareTo(warningAmount) >= 0)
                .build();
    }

    private BudgetCategoryEntity findCategory(BudgetEntity budget, Long categoryId) {
        return categoryRepository.findByIdAndBudget(categoryId, budget)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));
    }

    private BudgetEntity findOwnedBudget(UserEntity owner, Long budgetId) {
        BudgetEntity budget = budgetRepository.findById(budgetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Budget not found"));
        if (!budget.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the budget owner can manage categories");
        }
        return budget;
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    private record DefaultCategory(String name, String limit) { }
}
