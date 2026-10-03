package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.FriendUserResponse;

import java.util.List;

public interface FriendService {

    List<FriendUserResponse> searchUsers(String email, String username);

    FriendUserResponse sendRequest(String email, String username);

    List<FriendUserResponse> getPendingRequests(String email);

    List<FriendUserResponse> getFriends(String email);

    void acceptRequest(String email, Long requestId);

    void declineRequest(String email, Long requestId);
}
