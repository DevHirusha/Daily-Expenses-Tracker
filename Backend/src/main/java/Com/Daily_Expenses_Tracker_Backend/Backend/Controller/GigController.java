package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1.0/gigs")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class GigController {

    private final GigRepository gigRepository;

    @GetMapping
    public ResponseEntity<List<GigResponse>> getGigs() {
        return ResponseEntity.ok(
                gigRepository.findAll().stream()
                        .map(GigResponse::from)
                        .toList()
        );
    }
}
