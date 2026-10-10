package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.AnnouncementUserStateEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AnnouncementUserStateRepository
        extends JpaRepository<AnnouncementUserStateEntity, Long> {

    Optional<AnnouncementUserStateEntity> findByUserIdAndAnnouncementId(
            String userId,
            Long announcementId
    );

    List<AnnouncementUserStateEntity> findAllByUserId(String userId);
}
