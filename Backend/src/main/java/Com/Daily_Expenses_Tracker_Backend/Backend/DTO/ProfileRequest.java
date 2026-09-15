package Com.Daily_Expenses_Tracker_Backend.Backend.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ProfileRequest {

    private String name;
    private String email;
    private String password;
}
