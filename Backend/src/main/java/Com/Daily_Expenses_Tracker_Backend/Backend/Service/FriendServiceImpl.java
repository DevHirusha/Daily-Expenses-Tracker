package Com.Daily_Expenses_Tracker_Backend.Backend.Service;

import Com.Daily_Expenses_Tracker_Backend.Backend.DTO.FriendUserResponse;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.FriendListEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.FriendRequestEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.FriendRequestStatus;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.FriendRequestRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.FriendListRepository;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class FriendServiceImpl implements FriendService {

    private final UserRepository userRepository;
    private final FriendRequestRepository friendRequestRepository;
        private final FriendListRepository friendListRepository;

    @Override
    @Transactional(readOnly = true)
    public List<FriendUserResponse> searchUsers(String email, String username) {
        UserEntity currentUser = getUser(email);
        String query = username == null ? "" : username.trim();
        if (query.length() < 2) {
            return List.of();
        }

        return userRepository
                .findTop20ByUsernameContainingIgnoreCaseAndUsernameNotOrderByUsernameAsc(
                        query,
                        currentUser.getUsername()
                )
                .stream()
                .map(user -> toResponse(user, findRequest(currentUser, user)))
                .toList();
    }

    @Override
    public FriendUserResponse sendRequest(String email, String username) {
        UserEntity requester = getUser(email);
        UserEntity recipient = userRepository.findByUsernameIgnoreCase(username.trim())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User not found"
                ));

        if (requester.getId().equals(recipient.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "You cannot send a friend request to yourself"
            );
        }

                FriendRequestEntity request = findRequest(requester, recipient);
                FriendRequestEntity reverse = findRequest(recipient, requester);

                if (request != null) {
            if (request.getStatus() == FriendRequestStatus.ACCEPTED) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "You are already friends");
            }
            if (request.getStatus() == FriendRequestStatus.PENDING) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Friend request already exists");
            }
            request.setRequester(requester);
            request.setRecipient(recipient);
            request.setStatus(FriendRequestStatus.PENDING);
                } else if (reverse != null) {
                        if (reverse.getStatus() == FriendRequestStatus.ACCEPTED) {
                                throw new ResponseStatusException(HttpStatus.CONFLICT, "You are already friends");
                        }
                        if (reverse.getStatus() == FriendRequestStatus.PENDING) {
                                throw new ResponseStatusException(
                                                HttpStatus.CONFLICT, "This user already sent you a friend request"
                                );
                        }
                        reverse.setRequester(requester);
                        reverse.setRecipient(recipient);
                        reverse.setStatus(FriendRequestStatus.PENDING);
                        request = reverse;
        } else {
            request = FriendRequestEntity.builder()
                    .requester(requester)
                    .recipient(recipient)
                    .status(FriendRequestStatus.PENDING)
                    .build();
        }

        return toResponse(recipient, friendRequestRepository.save(request));
    }

    @Override
    @Transactional(readOnly = true)
    public List<FriendUserResponse> getPendingRequests(String email) {
        UserEntity recipient = getUser(email);
        return friendRequestRepository
                .findByRecipientAndStatusOrderByCreatedAtDesc(
                        recipient,
                        FriendRequestStatus.PENDING
                )
                .stream()
                .map(request -> toResponse(request.getRequester(), request))
                .toList();
    }

    @Override
    public List<FriendUserResponse> getFriends(String email) {
        UserEntity currentUser = getUser(email);
                syncAcceptedFriendships();
        return friendListRepository
                .findByUserOrderByCreatedAtDesc(currentUser)
                .stream()
                .map(friend -> toResponse(friend.getFriend(), FriendRequestStatus.ACCEPTED.name(), null))
                .toList();
    }

        private void syncAcceptedFriendships() {
                friendRequestRepository
                        .findByStatusOrderByUpdatedAtDesc(FriendRequestStatus.ACCEPTED)
                                .forEach(request -> {
                                        saveFriendship(request.getRequester(), request.getRecipient());
                                        saveFriendship(request.getRecipient(), request.getRequester());
                                });
        }

    @Override
    public void acceptRequest(String email, Long requestId) {
        UserEntity recipient = getUser(email);
        FriendRequestEntity request = getRequestForRecipient(requestId, recipient);
        request.setStatus(FriendRequestStatus.ACCEPTED);
        friendRequestRepository.save(request);
        saveFriendship(request.getRequester(), request.getRecipient());
        saveFriendship(request.getRecipient(), request.getRequester());
    }

    @Override
    public void declineRequest(String email, Long requestId) {
        UserEntity recipient = getUser(email);
        FriendRequestEntity request = getRequestForRecipient(requestId, recipient);
        request.setStatus(FriendRequestStatus.DECLINED);
        friendRequestRepository.save(request);
    }

    private UserEntity getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Authenticated user not found"
                ));
    }

    private FriendRequestEntity getRequestForRecipient(Long requestId, UserEntity recipient) {
        FriendRequestEntity request = friendRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Friend request not found"
                ));
        if (!request.getRecipient().getId().equals(recipient.getId())
                || request.getStatus() != FriendRequestStatus.PENDING) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "This friend request is no longer available"
            );
        }
        return request;
    }

    private FriendRequestEntity findRequest(UserEntity requester, UserEntity recipient) {
        return friendRequestRepository.findByRequesterAndRecipient(requester, recipient)
                .orElse(null);
    }

        private void saveFriendship(UserEntity user, UserEntity friend) {
                if (!friendListRepository.existsByUserAndFriend(user, friend)) {
                        friendListRepository.save(FriendListEntity.builder()
                                        .user(user)
                                        .friend(friend)
                                        .build());
                }
        }

    private FriendUserResponse toResponse(
            UserEntity user,
            FriendRequestEntity request
    ) {
        return toResponse(
                user,
                request == null ? null : request.getStatus().name(),
                request == null ? null : request.getId()
        );
    }

    private FriendUserResponse toResponse(
            UserEntity user,
            String requestStatus,
            Long requestId
    ) {
        return FriendUserResponse.builder()
                .userId(user.getUserId())
                .username(user.getUsername())
                .name(user.getName())
                .email(user.getEmail())
                .requestStatus(requestStatus)
                .requestId(requestId)
                .build();
    }
}
