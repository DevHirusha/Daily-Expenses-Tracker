package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.SavingsGoalEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoalEntity, Long> {
    List<SavingsGoalEntity> findByOwnerOrderByTargetDateAsc(UserEntity owner);
    Optional<SavingsGoalEntity> findByIdAndOwner(Long id, UserEntity owner);
}
