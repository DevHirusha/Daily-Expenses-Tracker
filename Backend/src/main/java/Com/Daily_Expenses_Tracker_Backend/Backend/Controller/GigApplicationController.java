package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigApplicationRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigApplicationResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigApplicationUpdateRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationStatus;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigApplicationRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1.0/gig-applications")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class GigApplicationController {

    private final GigApplicationRepository applicationRepository;
    private final GigRepository gigRepository;
    private final UserRepository userRepository;

    @PostMapping
    public ResponseEntity<GigApplicationResponse> createApplication(
            @Valid @RequestBody GigApplicationRequest request,
            Authentication authentication
    ) {
        UserEntity applicant = currentUser(authentication);
        var gig = gigRepository.findById(request.getGigId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Gig not found"));

        if (gig.getApplicationDeadline() != null
                && gig.getApplicationDeadline().isBefore(LocalDate.now())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Applications for this gig are closed");
        }

        if (applicationRepository.existsByGig_IdAndApplicant_Id(gig.getId(), applicant.getId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "You have already applied for this gig");
        }

        GigApplicationEntity application = GigApplicationEntity.builder()
                .gig(gig)
                .applicant(applicant)
                .status(GigApplicationStatus.PENDING)
                .note(trimToNull(request.getNote()))
                .build();

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(GigApplicationResponse.from(applicationRepository.save(application)));
    }

    @GetMapping
    public ResponseEntity<List<GigApplicationResponse>> getMyApplications(Authentication authentication) {
        UserEntity applicant = currentUser(authentication);
        return ResponseEntity.ok(applicationRepository.findByApplicant_IdOrderByCreatedAtDesc(applicant.getId())
                .stream()
                .map(GigApplicationResponse::from)
                .toList());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Void> updateApplication(
            @PathVariable Long id,
            @Valid @RequestBody GigApplicationUpdateRequest request,
            Authentication authentication
    ) {
        GigApplicationEntity application = findOwnedApplication(id, authentication);
        requirePending(application);
        application.setNote(trimToNull(request.getNote()));
        applicationRepository.saveAndFlush(application);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteApplication(
            @PathVariable Long id,
            Authentication authentication
    ) {
        GigApplicationEntity application = findOwnedApplication(id, authentication);
        if (application.getStatus() == GigApplicationStatus.APPROVED) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Approved applications cannot be deleted");
        }
        applicationRepository.delete(application);
        return ResponseEntity.noContent().build();
    }

    private GigApplicationEntity findOwnedApplication(Long id, Authentication authentication) {
        UserEntity applicant = currentUser(authentication);
        GigApplicationEntity application = applicationRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Application not found"));
        if (!application.getApplicant().getId().equals(applicant.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only manage your own applications");
        }
        return application;
    }

    private void requirePending(GigApplicationEntity application) {
        if (application.getStatus() != GigApplicationStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Only pending applications can be edited");
        }
    }

    private UserEntity currentUser(Authentication authentication) {
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User account not found"));
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
