package Com.Daily_Expenses_Tracker_Backend.Backend.Controller;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateBudgetRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupMemberResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.UpdateBudgetProofRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.UpdateBudgetSplitRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateSettlementRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SettlementResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Service.BudgetService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.CurrentSecurityContext;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PutMapping;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1.0/budgets")
public class BudgetController {
    private final BudgetService budgetService;

    @PostMapping
    public BudgetResponse create(
            @Valid @RequestBody CreateBudgetRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return budgetService.createBudget(email, request);
    }

    @GetMapping
    public List<BudgetResponse> getAll(
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return budgetService.getBudgets(email);
    }

    @GetMapping("/{budgetId}/members")
    public List<GroupMemberResponse> getMembers(
            @PathVariable Long budgetId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return budgetService.getMembers(email, budgetId);
    }

    @PostMapping("/{budgetId}/members/{userId}")
    public void addMember(
            @PathVariable Long budgetId,
            @PathVariable String userId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        budgetService.addMember(email, budgetId, userId);
    }

    @DeleteMapping("/{budgetId}")
    public void delete(
            @PathVariable Long budgetId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        budgetService.deleteBudget(email, budgetId);
    }

    @PutMapping("/{budgetId}/proof")
    public void updateProof(
            @PathVariable Long budgetId,
            @Valid @RequestBody UpdateBudgetProofRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        budgetService.updateProof(email, budgetId, request.getProofData());
    }

    @PutMapping("/{budgetId}/split")
    public void updateSplit(
            @PathVariable Long budgetId,
            @Valid @RequestBody UpdateBudgetSplitRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        budgetService.updateSplit(email, budgetId, request.getPercentages());
    }

    @PostMapping("/{budgetId}/settlements")
    public void saveSettlement(
            @PathVariable Long budgetId,
            @Valid @RequestBody CreateSettlementRequest request,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        budgetService.saveSettlement(email, budgetId, request.getAmount(), request.getProofData());
    }

    @GetMapping("/{budgetId}/settlements")
    public List<SettlementResponse> getSettlements(
            @PathVariable Long budgetId,
            @CurrentSecurityContext(expression = "authentication?.name") String email) {
        return budgetService.getSettlements(email, budgetId);
    }
}