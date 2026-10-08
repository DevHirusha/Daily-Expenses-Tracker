package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalHistoryResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.UpdateSavingsGoalSavedRequest;

import java.util.List;

public interface SavingsGoalService {
    SavingsGoalResponse create(String email, SavingsGoalRequest request);
    List<SavingsGoalResponse> getAll(String email);
    SavingsGoalResponse getOne(String email, Long goalId);
    SavingsGoalResponse update(String email, Long goalId, SavingsGoalRequest request);
    SavingsGoalResponse updateSavedAmount(String email, Long goalId, UpdateSavingsGoalSavedRequest request);
    List<SavingsGoalHistoryResponse> getHistory(String email, Long goalId);
    void delete(String email, Long goalId);
}
