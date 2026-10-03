package Com.Daily_Expenses_Tracker_Backend.Backend.Repository;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.GroupMemberEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GroupMemberRepository extends JpaRepository<GroupMemberEntity, Long> {

    boolean existsByGroupAndUser(GroupEntity group, UserEntity user);

    long countByGroup(GroupEntity group);

    List<GroupMemberEntity> findByGroupOrderByCreatedAtAsc(GroupEntity group);

    Optional<GroupMemberEntity> findByGroupAndUser(GroupEntity group, UserEntity user);

    @Query("select member.group from GroupMemberEntity member where member.user = :user order by member.createdAt desc")
    List<GroupEntity> findGroupsForUser(@Param("user") UserEntity user);
}
