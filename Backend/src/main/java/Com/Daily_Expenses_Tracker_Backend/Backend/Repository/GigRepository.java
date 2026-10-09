package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GigRepository extends JpaRepository<GigEntity, Long> {
}
