package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class GroupMemberResponse {
    String userId;
    String username;
    String name;
    String email;
    String role;
}
