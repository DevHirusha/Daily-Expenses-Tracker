package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetCategoryEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.ExpenseEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ExpenseRepository extends JpaRepository<ExpenseEntity, Long> {
    long countByCategory(BudgetCategoryEntity category);

    Optional<ExpenseEntity> findByIdAndBudget(Long id, BudgetEntity budget);

    List<ExpenseEntity> findByBudgetAndCategoryAndExpenseDateBetweenOrderByExpenseDateDescIdDesc(
            BudgetEntity budget,
            BudgetCategoryEntity category,
            LocalDate start,
            LocalDate end);

    List<ExpenseEntity> findByBudgetAndExpenseDateBetweenOrderByExpenseDateDescIdDesc(
            BudgetEntity budget,
            LocalDate start,
            LocalDate end);

    @Query("select coalesce(sum(e.amount), 0) from ExpenseEntity e "
            + "where e.budget = :budget and e.category = :category "
            + "and e.expenseDate between :start and :end")
    BigDecimal sumAmount(
            @Param("budget") BudgetEntity budget,
            @Param("category") BudgetCategoryEntity category,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);
}
