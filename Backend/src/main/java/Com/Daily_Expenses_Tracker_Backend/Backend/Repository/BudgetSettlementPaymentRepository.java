package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetSettlementPaymentEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BudgetSettlementPaymentRepository
        extends JpaRepository<BudgetSettlementPaymentEntity, Long> {
    List<BudgetSettlementPaymentEntity> findByBudgetAndPayerOrderByCreatedAtAsc(
            BudgetEntity budget,
            UserEntity payer);
}
