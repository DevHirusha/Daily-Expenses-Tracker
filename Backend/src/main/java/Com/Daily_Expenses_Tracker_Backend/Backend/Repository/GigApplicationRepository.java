package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationEntity;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GigApplicationRepository extends JpaRepository<GigApplicationEntity, Long> {

    @EntityGraph(attributePaths = {"gig", "applicant"})
    List<GigApplicationEntity> findByApplicant_IdOrderByCreatedAtDesc(Long applicantId);

    @Override
    @EntityGraph(attributePaths = {"gig", "applicant"})
    List<GigApplicationEntity> findAll();

    @Override
    @EntityGraph(attributePaths = {"gig", "applicant"})
    java.util.Optional<GigApplicationEntity> findById(Long id);

    boolean existsByGig_IdAndApplicant_Id(Long gigId, Long applicantId);

    void deleteAllByGig_Id(Long gigId);

    void deleteAllByApplicant_Id(Long applicantId);
}
