package Com.Daily_Expenses_Tracker_Backend.Backend.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "tbl_announcement_user_states",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "announcement_id"})
)
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AnnouncementUserStateEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false, length = 100)
    private String userId;

    @Column(name = "announcement_id", nullable = false)
    private Long announcementId;

    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private boolean read = false;

    @Column(nullable = false)
    @Builder.Default
    private boolean dismissed = false;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
