package Com.Daily_Expenses_Tracker_Backend.Backend.Controller.Admin;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigApplicationResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GigApplicationStatusRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GigApplicationStatus;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GigApplicationRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;

@RestController
@RequestMapping("/admin/gig-applications")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
public class AdminGigApplicationController {

    private final GigApplicationRepository applicationRepository;

    @GetMapping
    public ResponseEntity<List<GigApplicationResponse>> getAllApplications() {
        return ResponseEntity.ok(applicationRepository.findAll().stream()
                .map(GigApplicationResponse::from)
                .toList());
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<GigApplicationResponse> updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody GigApplicationStatusRequest request
    ) {
        if (request.getStatus().name().equals("PENDING")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose approve or reject for an application");
        }
        GigApplicationEntity application = applicationRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Application not found"));
        if (application.getStatus() != GigApplicationStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This application has already been reviewed");
        }
        application.setStatus(request.getStatus());
        return ResponseEntity.ok(GigApplicationResponse.from(applicationRepository.save(application)));
    }
}
