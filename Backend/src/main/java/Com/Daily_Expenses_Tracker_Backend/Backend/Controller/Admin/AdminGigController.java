package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigApplicationRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RestController
@RequestMapping("/admin/gigs")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
public class AdminGigController {

    private final GigRepository gigRepository;
    private final GigApplicationRepository applicationRepository;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<GigResponse>> getAllGigs() {
        return ResponseEntity.ok(
                gigRepository.findAll().stream()
                        .map(GigResponse::from)
                        .toList()
        );
    }

    @PostMapping
    public ResponseEntity<GigResponse> createGig(
            @Valid @RequestBody GigRequest request,
            Authentication authentication
    ) {
        UserEntity creator = getCurrentUser(authentication);
        GigEntity gig = GigEntity.builder()
                .title(request.getTitle().trim())
                .description(request.getDescription().trim())
                .requirements(trimToNull(request.getRequirements()))
                .category(request.getCategory())
                .estimatedEarnings(trimToNull(request.getEstimatedEarnings()))
                .location(trimToNull(request.getLocation()))
                .companyName(trimToNull(request.getCompanyName()))
                .companyPhoneNumber(trimToNull(request.getCompanyPhoneNumber()))
                .applicationDeadline(request.getApplicationDeadline())
                .imageData(request.getImageData())
                .createdByUserId(creator.getUserId())
                .createdByName(creator.getName())
                .createdByEmail(creator.getEmail())
                .build();

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(GigResponse.from(gigRepository.save(gig)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<GigResponse> updateGig(
            @PathVariable Long id,
            @Valid @RequestBody GigRequest request
    ) {
        GigEntity gig = findGig(id);
        gig.setTitle(request.getTitle().trim());
        gig.setDescription(request.getDescription().trim());
        gig.setRequirements(trimToNull(request.getRequirements()));
        gig.setCategory(request.getCategory());
        gig.setEstimatedEarnings(trimToNull(request.getEstimatedEarnings()));
        gig.setLocation(trimToNull(request.getLocation()));
        gig.setCompanyName(trimToNull(request.getCompanyName()));
        gig.setCompanyPhoneNumber(trimToNull(request.getCompanyPhoneNumber()));
        gig.setApplicationDeadline(request.getApplicationDeadline());
        gig.setImageData(request.getImageData());

        return ResponseEntity.ok(GigResponse.from(gigRepository.save(gig)));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> deleteGig(@PathVariable Long id) {
        GigEntity gig = findGig(id);
        applicationRepository.deleteAllByGig_Id(id);
        gigRepository.delete(gig);
        return ResponseEntity.noContent().build();
    }

    private UserEntity getCurrentUser(Authentication authentication) {
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));
    }

    private GigEntity findGig(Long id) {
        return gigRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Gig not found"));
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
