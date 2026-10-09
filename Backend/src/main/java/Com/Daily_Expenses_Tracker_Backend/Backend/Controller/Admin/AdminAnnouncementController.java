package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AnnouncementRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AnnouncementResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.AnnouncementEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.AnnouncementRepository;
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

@RestController
@RequestMapping("/admin/announcements")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
public class AdminAnnouncementController {

    private final AnnouncementRepository announcementRepository;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<AnnouncementResponse>> getAllAnnouncements() {
        return ResponseEntity.ok(
                announcementRepository.findAll().stream()
                        .map(AnnouncementResponse::from)
                        .toList()
        );
    }

    @PostMapping
    public ResponseEntity<AnnouncementResponse> createAnnouncement(
            @Valid @RequestBody AnnouncementRequest request,
            Authentication authentication
    ) {
        UserEntity creator = getCurrentUser(authentication);
        AnnouncementEntity announcement = AnnouncementEntity.builder()
                .title(request.getTitle().trim())
                .message(request.getMessage().trim())
                .createdByUserId(creator.getUserId())
                .createdByName(creator.getName())
                .createdByEmail(creator.getEmail())
                .build();

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(AnnouncementResponse.from(announcementRepository.save(announcement)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AnnouncementResponse> updateAnnouncement(
            @PathVariable Long id,
            @Valid @RequestBody AnnouncementRequest request
    ) {
        AnnouncementEntity announcement = findAnnouncement(id);
        announcement.setTitle(request.getTitle().trim());
        announcement.setMessage(request.getMessage().trim());

        return ResponseEntity.ok(AnnouncementResponse.from(announcementRepository.save(announcement)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAnnouncement(@PathVariable Long id) {
        announcementRepository.delete(findAnnouncement(id));
        return ResponseEntity.noContent().build();
    }

    private UserEntity getCurrentUser(Authentication authentication) {
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin account not found"));
    }

    private AnnouncementEntity findAnnouncement(Long id) {
        return announcementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Announcement not found"));
    }
}
