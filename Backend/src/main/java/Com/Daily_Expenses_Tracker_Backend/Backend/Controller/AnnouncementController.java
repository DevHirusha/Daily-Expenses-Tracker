package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.AnnouncementResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.AnnouncementEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.AnnouncementUserStateEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.AnnouncementRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.AnnouncementUserStateRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1.0/announcements")
public class AnnouncementController {

    private final AnnouncementRepository announcementRepository;
    private final AnnouncementUserStateRepository stateRepository;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<AnnouncementResponse>> getAnnouncements(
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        UserEntity user = getCurrentUser(email);
        Map<Long, AnnouncementUserStateEntity> states = stateRepository.findAllByUserId(user.getUserId())
                .stream()
                .collect(Collectors.toMap(
                        AnnouncementUserStateEntity::getAnnouncementId,
                        Function.identity()
                ));

        return ResponseEntity.ok(
                announcementRepository.findAllByOrderByCreatedAtDesc().stream()
                        .filter(announcement -> {
                            AnnouncementUserStateEntity state = states.get(announcement.getId());
                            return state == null || !state.isDismissed();
                        })
                        .map(announcement -> {
                            AnnouncementUserStateEntity state = states.get(announcement.getId());
                            return AnnouncementResponse.from(
                                    announcement,
                                    state != null && state.isRead()
                            );
                        })
                        .toList()
        );
    }

    @PostMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead(
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        UserEntity user = getCurrentUser(email);
        for (AnnouncementEntity announcement : announcementRepository.findAll()) {
            AnnouncementUserStateEntity state = getOrCreateState(user, announcement.getId());
            state.setRead(true);
            stateRepository.save(state);
        }
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable Long id,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        if (!announcementRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Announcement not found");
        }
        UserEntity user = getCurrentUser(email);
        AnnouncementUserStateEntity state = getOrCreateState(user, id);
        state.setRead(true);
        stateRepository.save(state);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> clearAll(
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        UserEntity user = getCurrentUser(email);
        for (AnnouncementEntity announcement : announcementRepository.findAll()) {
            AnnouncementUserStateEntity state = getOrCreateState(user, announcement.getId());
            state.setRead(true);
            state.setDismissed(true);
            stateRepository.save(state);
        }
        return ResponseEntity.noContent().build();
    }

    private UserEntity getCurrentUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "User account not found"
                ));
    }

    private AnnouncementUserStateEntity getOrCreateState(UserEntity user, Long announcementId) {
        return stateRepository.findByUserIdAndAnnouncementId(user.getUserId(), announcementId)
                .orElseGet(() -> AnnouncementUserStateEntity.builder()
                        .userId(user.getUserId())
                        .announcementId(announcementId)
                        .build());
    }
}
