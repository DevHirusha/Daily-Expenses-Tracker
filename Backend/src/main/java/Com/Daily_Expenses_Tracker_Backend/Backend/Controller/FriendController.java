package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.FriendUserResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.FriendService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1.0/friends")
public class FriendController {

    private final FriendService friendService;

    @GetMapping("/search")
    public List<FriendUserResponse> searchUsers(
            @RequestParam String username,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return friendService.searchUsers(email, username);
    }

    @PostMapping("/requests/{username}")
    public FriendUserResponse sendRequest(
            @PathVariable String username,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return friendService.sendRequest(email, username);
    }

    @GetMapping("/requests")
    public List<FriendUserResponse> getRequests(
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return friendService.getPendingRequests(email);
    }

    @GetMapping
    public List<FriendUserResponse> getFriends(
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return friendService.getFriends(email);
    }

    @PostMapping("/requests/{requestId}/accept")
    public ResponseEntity<Void> acceptRequest(
            @PathVariable Long requestId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        friendService.acceptRequest(email, requestId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/requests/{requestId}/decline")
    public ResponseEntity<Void> declineRequest(
            @PathVariable Long requestId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        friendService.declineRequest(email, requestId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}
