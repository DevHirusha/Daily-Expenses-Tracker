package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<UserEntity, Long> {

     Optional<UserEntity> findByEmail (String email);

     Boolean existsByEmail(String email);

     Boolean existsByUsername(String username);

          Optional<UserEntity> findByUsernameIgnoreCase(String username);

          Optional<UserEntity> findByUserId(String userId);

          List<UserEntity> findTop20ByUsernameContainingIgnoreCaseAndUsernameNotOrderByUsernameAsc(
               String username,
               String currentUsername
          );
}
