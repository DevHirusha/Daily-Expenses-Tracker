package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateGroupRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupMemberResponse;

import java.util.List;

public interface GroupService {

    GroupResponse createGroup(String email, CreateGroupRequest request);

    GroupResponse joinGroup(String email, String joinCode);

    GroupResponse resetJoinCode(String email, Long groupId);

    List<GroupResponse> getGroups(String email);

    List<GroupMemberResponse> getMembers(String email, Long groupId);

    void addMember(String email, Long groupId, String userId);

    void removeMember(String email, Long groupId, String userId);

    void leaveGroup(String email, Long groupId);
}
