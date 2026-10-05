package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GroupRepository extends JpaRepository<GroupEntity, Long> {

    boolean existsByJoinCode(String joinCode);

    Optional<GroupEntity> findByJoinCode(String joinCode);

    List<GroupEntity> findByOwnerOrderByCreatedAtDesc(UserEntity owner);
}
