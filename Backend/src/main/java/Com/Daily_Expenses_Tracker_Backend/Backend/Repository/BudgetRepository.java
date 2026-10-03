package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface BudgetRepository extends JpaRepository<BudgetEntity, Long> {
    List<BudgetEntity> findByOwnerOrderByIdDesc(UserEntity owner);

    @Query("select b from BudgetEntity b join b.memberUserIds memberId where memberId = :userId order by b.id desc")
    List<BudgetEntity> findSharedByMemberUserId(@Param("userId") String userId);
}