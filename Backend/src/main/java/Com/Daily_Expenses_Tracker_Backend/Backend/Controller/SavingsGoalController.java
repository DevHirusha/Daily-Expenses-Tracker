package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalHistoryResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.UpdateSavingsGoalSavedRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.SavingsGoalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1.0/savings-goals")
public class SavingsGoalController {
    private final SavingsGoalService savingsGoalService;

    @PostMapping
    public SavingsGoalResponse create(
            @Valid @RequestBody SavingsGoalRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return savingsGoalService.create(email, request);
    }

    @GetMapping
    public List<SavingsGoalResponse> getAll(
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return savingsGoalService.getAll(email);
    }

    @GetMapping("/{goalId}")
    public SavingsGoalResponse getOne(
            @PathVariable Long goalId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return savingsGoalService.getOne(email, goalId);
    }

    @PutMapping("/{goalId}")
    public SavingsGoalResponse update(
            @PathVariable Long goalId,
            @Valid @RequestBody SavingsGoalRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return savingsGoalService.update(email, goalId, request);
    }

    @PatchMapping("/{goalId}/saved")
    public SavingsGoalResponse updateSavedAmount(
            @PathVariable Long goalId,
            @Valid @RequestBody UpdateSavingsGoalSavedRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return savingsGoalService.updateSavedAmount(email, goalId, request);
    }

    @GetMapping("/{goalId}/history")
    public List<SavingsGoalHistoryResponse> getHistory(
            @PathVariable Long goalId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return savingsGoalService.getHistory(email, goalId);
    }

    @DeleteMapping("/{goalId}")
    public void delete(
            @PathVariable Long goalId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        savingsGoalService.delete(email, goalId);
    }
}
