package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.FriendRequestEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.FriendRequestStatus;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FriendRequestRepository extends JpaRepository<FriendRequestEntity, Long> {

    Optional<FriendRequestEntity> findByRequesterAndRecipient(
            UserEntity requester,
            UserEntity recipient
    );

    List<FriendRequestEntity> findByRecipientAndStatusOrderByCreatedAtDesc(
            UserEntity recipient,
            FriendRequestStatus status
    );

    List<FriendRequestEntity> findByStatusOrderByUpdatedAtDesc(FriendRequestStatus status);

    @Query("""
            select request from FriendRequestEntity request
            where request.status = :status
              and (request.requester = :user or request.recipient = :user)
            order by request.updatedAt desc
            """)
    List<FriendRequestEntity> findConnections(
            @Param("user") UserEntity user,
            @Param("status") FriendRequestStatus status
    );
}
