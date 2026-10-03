package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetSettlementEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface BudgetSettlementRepository extends JpaRepository<BudgetSettlementEntity, Long> {
    Optional<BudgetSettlementEntity> findByBudgetAndPayer(BudgetEntity budget, UserEntity payer);
    List<BudgetSettlementEntity> findByBudgetOrderByCreatedAtAsc(BudgetEntity budget);
}