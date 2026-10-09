package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.SavingsGoalEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.SavingsGoalHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SavingsGoalHistoryRepository extends JpaRepository<SavingsGoalHistoryEntity, Long> {
    List<SavingsGoalHistoryEntity> findByGoalOrderBySavedAtDescIdDesc(SavingsGoalEntity goal);

    void deleteByGoal(SavingsGoalEntity goal);
}
