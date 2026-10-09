package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetCategoryEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BudgetCategoryRepository extends JpaRepository<BudgetCategoryEntity, Long> {
    List<BudgetCategoryEntity> findByBudgetOrderByIdAsc(BudgetEntity budget);
    Optional<BudgetCategoryEntity> findByIdAndBudget(Long id, BudgetEntity budget);
    Optional<BudgetCategoryEntity> findByBudgetAndNameIgnoreCase(BudgetEntity budget, String name);
}
