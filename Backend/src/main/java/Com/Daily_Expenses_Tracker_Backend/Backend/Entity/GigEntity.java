package Com.Daily_Expenses_Tracker_Backend.Backend.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "tbl_gigs")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class GigEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String requirements;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private GigCategory category;

    @Column(length = 100)
    private String estimatedEarnings;

    @Column(length = 150)
    private String location;

    @Column(length = 150)
    private String companyName;

    @Column(length = 30)
    private String companyPhoneNumber;

    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String imageData;

    @Column(length = 100)
    private String createdByUserId;

    @Column(nullable = false, length = 100)
    private String createdByName;

    @Column(nullable = false, length = 150)
    private String createdByEmail;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
