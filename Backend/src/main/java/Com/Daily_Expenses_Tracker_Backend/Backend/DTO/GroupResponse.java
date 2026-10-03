package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class GroupResponse {
    Long id;
    String name;
    String joinCode;
    int memberCount;
    boolean owner;
}
