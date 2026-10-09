package Com.Daily_Expenses_Tracker_Backend.Backend.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "tbl_savings_goals")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SavingsGoalEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private UserEntity owner;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(length = 40)
    private String type;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal targetAmount;

    @Column(nullable = false)
    private LocalDate targetDate;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal savedAmount;

    @Column(nullable = false, length = 20)
    private String status;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
