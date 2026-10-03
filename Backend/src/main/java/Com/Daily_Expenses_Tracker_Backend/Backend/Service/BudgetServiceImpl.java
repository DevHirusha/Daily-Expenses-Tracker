package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.BudgetResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.CreateBudgetRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.GroupMemberResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SettlementResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.FriendListRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GroupMemberRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.GroupRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.BudgetSettlementRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.BudgetSettlementEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.ArrayList;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class BudgetServiceImpl implements BudgetService {
    private final BudgetRepository budgetRepository;
    private final FriendListRepository friendListRepository;
    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final BudgetSettlementRepository settlementRepository;

    @Override
    @Transactional
    public BudgetResponse createBudget(String email, CreateBudgetRequest request) {
        UserEntity owner = findUser(email);
        GroupEntity group = null;
        if (request.getGroupId() != null) {
            group = groupRepository.findById(request.getGroupId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Group not found"));
            if (!groupMemberRepository.existsByGroupAndUser(group, owner)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You are not a member of this group");
            }
        }
        List<String> memberIds = request.getMemberUserIds() == null ? List.of() : request.getMemberUserIds();
        for (String userId : memberIds) {
            UserEntity member = userRepository.findByUserId(userId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Budget member not found"));
            boolean inGroup = group != null && groupMemberRepository.existsByGroupAndUser(group, member);
            if (!inGroup && !friendListRepository.existsByUserAndFriend(owner, member)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Budget members must be in the group or your friend list");
            }
        }
        BudgetEntity budget = budgetRepository.save(BudgetEntity.builder()
                .name(request.getName().trim())
                .amount(request.getAmount())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .owner(owner)
                .group(group)
                .memberUserIds(memberIds)
                .proofData(request.getProofData())
                .build());
        return toResponse(budget, true, owner);
    }

    @Override
    @Transactional(readOnly = true)
    public List<BudgetResponse> getBudgets(String email) {
        UserEntity user = findUser(email);
        Stream<BudgetResponse> owned = budgetRepository.findByOwnerOrderByIdDesc(user).stream()
            .map(budget -> toResponse(budget, true, user));
        Stream<BudgetResponse> shared = budgetRepository.findSharedByMemberUserId(user.getUserId()).stream()
            .filter(budget -> !budget.getOwner().getId().equals(user.getId()))
                .map(budget -> toResponse(budget, false, user));
        return Stream.concat(owned, shared).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupMemberResponse> getMembers(String email, Long budgetId) {
        UserEntity viewer = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getOwner().getId().equals(viewer.getId())
                && !budget.getMemberUserIds().contains(viewer.getUserId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not have access to this budget");
        }
        return budget.getMemberUserIds().stream()
                .map(userRepository::findByUserId)
                .flatMap(java.util.Optional::stream)
                .map(user -> GroupMemberResponse.builder()
                        .userId(user.getUserId())
                        .username(user.getUsername())
                        .name(user.getName())
                        .email(user.getEmail())
                        .role(user.getId().equals(budget.getOwner().getId()) ? "OWNER" : "MEMBER")
                        .build())
                .toList();
    }

    @Override
    @Transactional
    public void addMember(String email, Long budgetId, String userId) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the budget owner can add members");
        }
        UserEntity member = userRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if (!friendListRepository.existsByUserAndFriend(owner, member)
                && (budget.getGroup() == null || !groupMemberRepository.existsByGroupAndUser(budget.getGroup(), member))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Budget members must be friends or group members");
        }
        if (!budget.getMemberUserIds().contains(userId)) {
            budget.getMemberUserIds().add(userId);
            budgetRepository.save(budget);
        }
    }

    @Override
    @Transactional
    public void deleteBudget(String email, Long budgetId) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the budget owner can delete it");
        }
        budgetRepository.delete(budget);
    }

    @Override
    @Transactional
    public void updateProof(String email, Long budgetId, String proofData) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the budget owner can edit proof");
        }
        budget.setProofData(proofData);
        budgetRepository.save(budget);
    }

    @Override
    @Transactional
    public void updateSplit(String email, Long budgetId, java.util.Map<String, Double> percentages) {
        UserEntity owner = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the budget owner can edit the split");
        }
        double total = percentages == null ? 0 : percentages.values().stream().mapToDouble(Double::doubleValue).sum();
        if (total > 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Fixed percentages cannot exceed 100%");
        }
        try {
            budget.setSplitPercentages(objectMapper.writeValueAsString(percentages == null ? java.util.Map.of() : percentages));
            budgetRepository.save(budget);
        } catch (JsonProcessingException error) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Could not save budget split", error);
        }
    }

    @Override
    @Transactional
    public void saveSettlement(String email, Long budgetId, String proofData) {
        saveSettlement(email, budgetId, BigDecimal.ZERO, proofData);
    }

    @Override
    @Transactional
    public void saveSettlement(String email, Long budgetId, BigDecimal amount, String proofData) {
        UserEntity payer = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getMemberUserIds().contains(payer.getUserId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You are not a member of this budget");
        }
        BigDecimal payable = calculatePayableAmount(budget, payer);
        if (amount == null || amount.signum() <= 0 || amount.compareTo(payable) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment must be greater than zero and not exceed your share");
        }
        BudgetSettlementEntity settlement = settlementRepository
                .findByBudgetAndPayer(budget, payer)
                .orElseGet(() -> BudgetSettlementEntity.builder()
                        .budget(budget)
                        .payer(payer)
                        .build());
        settlement.setAmount(amount);
        settlement.setProofData(proofData);
        settlementRepository.save(settlement);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SettlementResponse> getSettlements(String email, Long budgetId) {
        UserEntity viewer = findUser(email);
        BudgetEntity budget = findBudget(budgetId);
        if (!budget.getOwner().getId().equals(viewer.getId())
                && !budget.getMemberUserIds().contains(viewer.getUserId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not have access to this budget");
        }
        return settlementRepository.findByBudgetOrderByCreatedAtAsc(budget).stream()
                .map(settlement -> {
                    BigDecimal payable = calculatePayableAmount(budget, settlement.getPayer());
                    BigDecimal paid = settlement.getAmount() == null ? BigDecimal.ZERO : settlement.getAmount();
                    BigDecimal remaining = payable.subtract(paid).max(BigDecimal.ZERO);
                    return SettlementResponse.builder()
                            .payerUserId(settlement.getPayer().getUserId())
                            .payerName(settlement.getPayer().getName())
                            .amount(paid)
                            .remainingAmount(remaining)
                            .fullyPaid(remaining.signum() == 0)
                            .currentUser(settlement.getPayer().getId().equals(viewer.getId()))
                            .proofData(settlement.getProofData())
                            .build();
                })
                .toList();
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    private BudgetEntity findBudget(Long budgetId) {
        return budgetRepository.findById(budgetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Budget not found"));
    }

    private BudgetResponse toResponse(BudgetEntity budget, boolean owner, UserEntity viewer) {
        BigDecimal payableAmount = calculatePayableAmount(budget, viewer);
        return BudgetResponse.builder()
                .id(budget.getId())
                .name(budget.getName())
                .amount(budget.getAmount())
                .startDate(budget.getStartDate())
                .endDate(budget.getEndDate())
                .groupId(budget.getGroup() == null ? null : budget.getGroup().getId())
                .groupName(budget.getGroup() == null ? null : budget.getGroup().getName())
                .ownerName(budget.getOwner().getName())
                .payableAmount(payableAmount)
                .memberUserIds(new ArrayList<>(budget.getMemberUserIds()))
                .proofData(budget.getProofData())
                .splitPercentages(budget.getSplitPercentages())
                .owner(owner)
                .build();
    }

    private BigDecimal calculatePayableAmount(BudgetEntity budget, UserEntity viewer) {
        if (!budget.getMemberUserIds().contains(viewer.getUserId()) || budget.getMemberUserIds().isEmpty()) {
            return BigDecimal.ZERO.setScale(2);
        }
        java.util.Map<String, Double> percentages = java.util.Map.of();
        if (budget.getSplitPercentages() != null && !budget.getSplitPercentages().isBlank()) {
            try {
                percentages = objectMapper.readValue(
                        budget.getSplitPercentages(),
                        objectMapper.getTypeFactory().constructMapType(java.util.HashMap.class, String.class, Double.class));
            } catch (Exception ignored) {
                percentages = java.util.Map.of();
            }
        }
        double fixedTotal = percentages.values().stream().mapToDouble(Double::doubleValue).sum();
        long flexibleCount = 0;
        for (String userId : budget.getMemberUserIds()) {
            if (!percentages.containsKey(userId)) {
                flexibleCount++;
            }
        }
        double percentage = percentages.containsKey(viewer.getUserId())
                ? percentages.get(viewer.getUserId())
                : flexibleCount == 0 ? 0 : (100 - fixedTotal) / flexibleCount;
        return budget.getAmount()
                .multiply(BigDecimal.valueOf(percentage))
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }
}