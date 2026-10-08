package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.SavingsGoalHistoryResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.UpdateSavingsGoalSavedRequest;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.SavingsGoalEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.SavingsGoalHistoryEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.SavingsGoalRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.SavingsGoalHistoryRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SavingsGoalServiceImpl implements SavingsGoalService {
    private final SavingsGoalRepository savingsGoalRepository;
    private final SavingsGoalHistoryRepository savingsGoalHistoryRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public SavingsGoalResponse create(String email, SavingsGoalRequest request) {
        UserEntity owner = findUser(email);
        validateAmounts(request.getTargetAmount(), request.getSavedAmount());
        SavingsGoalEntity goal = savingsGoalRepository.save(SavingsGoalEntity.builder()
                .owner(owner)
                .name(request.getName().trim())
                .type(trim(request.getType()))
                .targetAmount(request.getTargetAmount())
                .targetDate(request.getTargetDate())
                .savedAmount(request.getSavedAmount())
                .status(calculateStatus(request.getSavedAmount(), request.getTargetAmount(), request.getTargetDate()))
                .build());
        if (request.getSavedAmount().signum() > 0) {
            saveHistory(goal, request.getSavedAmount(), request.getSavedAmount(), "INITIAL");
        }
        return toResponse(goal);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SavingsGoalResponse> getAll(String email) {
        UserEntity owner = findUser(email);
        return savingsGoalRepository.findByOwnerOrderByTargetDateAsc(owner).stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public SavingsGoalResponse getOne(String email, Long goalId) {
        return toResponse(findGoal(findUser(email), goalId));
    }

    @Override
    @Transactional
    public SavingsGoalResponse update(String email, Long goalId, SavingsGoalRequest request) {
        SavingsGoalEntity goal = findGoal(findUser(email), goalId);
        validateAmounts(request.getTargetAmount(), request.getSavedAmount());
        BigDecimal previousAmount = goal.getSavedAmount();
        goal.setName(request.getName().trim());
        goal.setType(trim(request.getType()));
        goal.setTargetAmount(request.getTargetAmount());
        goal.setTargetDate(request.getTargetDate());
        goal.setSavedAmount(request.getSavedAmount());
        goal.setStatus(calculateStatus(goal.getSavedAmount(), goal.getTargetAmount(), goal.getTargetDate()));
        SavingsGoalEntity savedGoal = savingsGoalRepository.save(goal);
        BigDecimal addedAmount = request.getSavedAmount().subtract(previousAmount);
        if (addedAmount.signum() > 0) {
            saveHistory(savedGoal, addedAmount, request.getSavedAmount(), "SAVED");
        }
        return toResponse(savedGoal);
    }

    @Override
    @Transactional
    public SavingsGoalResponse updateSavedAmount(String email, Long goalId, UpdateSavingsGoalSavedRequest request) {
        SavingsGoalEntity goal = findGoal(findUser(email), goalId);
        validateAmounts(goal.getTargetAmount(), request.getSavedAmount());
        BigDecimal previousAmount = goal.getSavedAmount();
        goal.setSavedAmount(request.getSavedAmount());
        goal.setStatus(calculateStatus(goal.getSavedAmount(), goal.getTargetAmount(), goal.getTargetDate()));
        SavingsGoalEntity savedGoal = savingsGoalRepository.save(goal);
        BigDecimal addedAmount = request.getSavedAmount().subtract(previousAmount);
        if (addedAmount.signum() > 0) {
            saveHistory(savedGoal, addedAmount, request.getSavedAmount(), "SAVED");
        }
        return toResponse(savedGoal);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SavingsGoalHistoryResponse> getHistory(String email, Long goalId) {
        SavingsGoalEntity goal = findGoal(findUser(email), goalId);
        return savingsGoalHistoryRepository.findByGoalOrderBySavedAtDescIdDesc(goal).stream()
                .map(this::toHistoryResponse)
                .toList();
    }

    @Override
    @Transactional
    public void delete(String email, Long goalId) {
        SavingsGoalEntity goal = findGoal(findUser(email), goalId);
        savingsGoalHistoryRepository.deleteByGoal(goal);
        savingsGoalRepository.delete(goal);
    }

    private SavingsGoalEntity findGoal(UserEntity owner, Long goalId) {
        return savingsGoalRepository.findByIdAndOwner(goalId, owner)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Savings goal not found"));
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    private void validateAmounts(BigDecimal target, BigDecimal saved) {
        if (target == null || target.signum() <= 0 || saved == null || saved.signum() < 0 || saved.compareTo(target) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Saved amount must be between zero and the target amount");
        }
    }

    private String calculateStatus(BigDecimal saved, BigDecimal target, LocalDate targetDate) {
        if (saved.compareTo(target) >= 0) return "COMPLETED";
        if (targetDate.isBefore(LocalDate.now())) return "BEHIND";
        return "ON_TRACK";
    }

    private SavingsGoalResponse toResponse(SavingsGoalEntity goal) {
        BigDecimal progress = goal.getTargetAmount().signum() == 0
                ? BigDecimal.ZERO
                : goal.getSavedAmount().multiply(BigDecimal.valueOf(100))
                    .divide(goal.getTargetAmount(), 2, RoundingMode.HALF_UP);
        return SavingsGoalResponse.builder()
                .id(goal.getId())
                .name(goal.getName())
                .type(goal.getType())
                .targetAmount(goal.getTargetAmount())
                .targetDate(goal.getTargetDate())
                .savedAmount(goal.getSavedAmount())
                .progressPercentage(progress)
                .status(calculateStatus(goal.getSavedAmount(), goal.getTargetAmount(), goal.getTargetDate()))
                .build();
    }

    private void saveHistory(SavingsGoalEntity goal, BigDecimal amount, BigDecimal balanceAfter, String entryType) {
        savingsGoalHistoryRepository.save(SavingsGoalHistoryEntity.builder()
                .goal(goal)
                .amount(amount)
                .balanceAfter(balanceAfter)
                .entryType(entryType)
                .savedAt(java.time.LocalDateTime.now())
                .build());
    }

    private SavingsGoalHistoryResponse toHistoryResponse(SavingsGoalHistoryEntity history) {
        return SavingsGoalHistoryResponse.builder()
                .id(history.getId())
                .amount(history.getAmount())
                .balanceAfter(history.getBalanceAfter())
                .entryType(history.getEntryType())
                .savedAt(history.getSavedAt())
                .build();
    }

    private String trim(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
