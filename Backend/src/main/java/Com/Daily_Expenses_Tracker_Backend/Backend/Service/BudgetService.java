package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateBudgetRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupMemberResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SettlementResponse;

import java.util.List;
import java.util.Map;

public interface BudgetService {
    BudgetResponse createBudget(String email, CreateBudgetRequest request);
    List<BudgetResponse> getBudgets(String email);
    List<GroupMemberResponse> getMembers(String email, Long budgetId);
    void addMember(String email, Long budgetId, String userId);
    void deleteBudget(String email, Long budgetId);
    void updateProof(String email, Long budgetId, String proofData);
    void updateSplit(String email, Long budgetId, Map<String, Double> percentages);
    void saveSettlement(String email, Long budgetId, String proofData);
    void saveSettlement(String email, Long budgetId, java.math.BigDecimal amount, String proofData);
    List<SettlementResponse> getSettlements(String email, Long budgetId);
}