package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.FriendListEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FriendListRepository extends JpaRepository<FriendListEntity, Long> {

    List<FriendListEntity> findByUserOrderByCreatedAtDesc(UserEntity user);

    boolean existsByUserAndFriend(UserEntity user, UserEntity friend);
}
