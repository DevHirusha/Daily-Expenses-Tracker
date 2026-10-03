package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateGroupRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupMemberResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupMemberEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.FriendListRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GroupMemberRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GroupRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class GroupServiceImpl implements GroupService {

    private final UserRepository userRepository;
    private final FriendListRepository friendListRepository;
    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;

    @Override
    public GroupResponse createGroup(String email, CreateGroupRequest request) {
        UserEntity owner = getUser(email);
        List<String> memberIds = request.getMemberUserIds() == null
                ? List.of()
                : new ArrayList<>(new HashSet<>(request.getMemberUserIds()));

        List<UserEntity> members = new ArrayList<>();
        for (String memberId : memberIds) {
            UserEntity member = userRepository.findByUserId(memberId)
                .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Selected member was not found"
                ));
            if (!friendListRepository.existsByUserAndFriend(owner, member)) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "You can only add accepted friends to a group"
            );
            }
            members.add(member);
        }

        GroupEntity group = groupRepository.save(GroupEntity.builder()
                .name(request.getName().trim())
                .joinCode(generateJoinCode())
                .owner(owner)
                .build());

        saveMember(group, owner, "OWNER");
        for (UserEntity member : members) {
            saveMember(group, member, "MEMBER");
        }

        return toResponse(group);
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupResponse> getGroups(String email) {
        UserEntity user = getUser(email);
        return groupMemberRepository.findGroupsForUser(user)
                .stream()
                .map(group -> toResponse(group, user))
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupMemberResponse> getMembers(String email, Long groupId) {
        UserEntity user = getUser(email);
        GroupEntity group = getGroupForMember(groupId, user);
        return groupMemberRepository.findByGroupOrderByCreatedAtAsc(group)
                .stream()
                .map(this::toMemberResponse)
                .toList();
    }

    @Override
    public void addMember(String email, Long groupId, String userId) {
        UserEntity currentUser = getUser(email);
        GroupEntity group = getGroupForMember(groupId, currentUser);
        UserEntity friend = userRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User not found"
                ));
        if (!friendListRepository.existsByUserAndFriend(currentUser, friend)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "You can only add accepted friends"
            );
        }
        if (groupMemberRepository.existsByGroupAndUser(group, friend)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "User is already in this group");
        }
        saveMember(group, friend, "MEMBER");
    }

    @Override
    public void removeMember(String email, Long groupId, String userId) {
        UserEntity owner = getUser(email);
        GroupEntity group = getGroupForMember(groupId, owner);
        if (!group.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the group owner can remove members");
        }
        UserEntity member = userRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        GroupMemberEntity membership = groupMemberRepository.findByGroupAndUser(group, member)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Member is not in this group"));
        if (member.getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "The owner cannot remove themselves");
        }
        groupMemberRepository.delete(membership);
    }

    @Override
    public void leaveGroup(String email, Long groupId) {
        UserEntity currentUser = getUser(email);
        GroupEntity group = getGroupForMember(groupId, currentUser);
        GroupMemberEntity membership = groupMemberRepository.findByGroupAndUser(group, currentUser)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Member is not in this group"));

        List<GroupMemberEntity> remaining = groupMemberRepository.findByGroupOrderByCreatedAtAsc(group)
                .stream()
                .filter(member -> !member.getUser().getId().equals(currentUser.getId()))
                .toList();
        groupMemberRepository.delete(membership);
        if (remaining.isEmpty()) {
            groupRepository.delete(group);
            return;
        }
        if (group.getOwner().getId().equals(currentUser.getId())) {
            GroupMemberEntity newOwner = remaining.get(0);
            newOwner.setRole("OWNER");
            group.setOwner(newOwner.getUser());
            groupRepository.save(group);
            groupMemberRepository.save(newOwner);
        }
    }

    private void saveMember(GroupEntity group, UserEntity user, String role) {
        if (!groupMemberRepository.existsByGroupAndUser(group, user)) {
            groupMemberRepository.save(GroupMemberEntity.builder()
                    .group(group)
                    .user(user)
                    .role(role)
                    .build());
        }
    }

    private String generateJoinCode() {
        String code;
        do {
            code = UUID.randomUUID().toString()
                    .replace("-", "")
                    .substring(0, 8)
                    .toUpperCase();
        } while (groupRepository.existsByJoinCode(code));
        return code;
    }

    private UserEntity getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Authenticated user not found"
                ));
    }

    private GroupEntity getGroupForMember(Long groupId, UserEntity user) {
        GroupEntity group = groupRepository.findById(groupId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Group not found"));
        if (!groupMemberRepository.existsByGroupAndUser(group, user)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You are not a member of this group");
        }
        return group;
    }

    private GroupMemberResponse toMemberResponse(GroupMemberEntity member) {
        UserEntity user = member.getUser();
        return GroupMemberResponse.builder()
                .userId(user.getUserId())
                .username(user.getUsername())
                .name(user.getName())
                .email(user.getEmail())
                .role(member.getRole())
                .build();
    }

    private GroupResponse toResponse(GroupEntity group) {
        return toResponse(group, group.getOwner());
    }

    private GroupResponse toResponse(GroupEntity group, UserEntity currentUser) {
        return GroupResponse.builder()
                .id(group.getId())
                .name(group.getName())
                .joinCode(group.getJoinCode())
                .memberCount((int) groupMemberRepository.countByGroup(group))
                .owner(group.getOwner().getId().equals(currentUser.getId()))
                .build();
    }
}
