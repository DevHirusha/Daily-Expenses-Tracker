package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.ProfileResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/v1.0")
@RequiredArgsConstructor
public class ProfileController {

      private final ProfileService profileService;

      @PostMapping("/register")
      public ProfileResponse register(@RequestBody ProfileRequest request) {
            ProfileResponse response = profileService.createProfile(request);
            // TODO: Welcome Email
            return response;
      }

}
