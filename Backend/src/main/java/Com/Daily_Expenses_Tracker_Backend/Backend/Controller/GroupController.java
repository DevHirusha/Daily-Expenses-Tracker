package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateGroupRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupMemberResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.GroupService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1.0/groups")
public class GroupController {

    private final GroupService groupService;

    @PostMapping
    public GroupResponse createGroup(
            @Valid @RequestBody CreateGroupRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return groupService.createGroup(email, request);
    }

    @PostMapping("/join")
    public GroupResponse joinGroup(
            @Valid @RequestBody JoinGroupRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return groupService.joinGroup(email, request.joinCode());
    }

    @PutMapping("/{groupId}/join-code")
    public GroupResponse resetJoinCode(
            @PathVariable Long groupId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return groupService.resetJoinCode(email, groupId);
    }

    @GetMapping
    public List<GroupResponse> getGroups(
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return groupService.getGroups(email);
    }

    @GetMapping("/{groupId}/members")
    public List<GroupMemberResponse> getMembers(
            @PathVariable Long groupId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        return groupService.getMembers(email, groupId);
    }

    @PostMapping("/{groupId}/members/{userId}")
    public ResponseEntity<Void> addMember(
            @PathVariable Long groupId,
            @PathVariable String userId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        groupService.addMember(email, groupId, userId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{groupId}/members/{userId}")
    public ResponseEntity<Void> removeMember(
            @PathVariable Long groupId,
            @PathVariable String userId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        groupService.removeMember(email, groupId, userId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{groupId}/leave")
    public ResponseEntity<Void> leaveGroup(
            @PathVariable Long groupId,
            @CurrentSecurityContext(expression = "authentication?.name") String email
    ) {
        groupService.leaveGroup(email, groupId);
        return ResponseEntity.noContent().build();
    }
}

record JoinGroupRequest(@NotBlank String joinCode) {}
