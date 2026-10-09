package Com.Daily_Expenses_Tracker_Backend.Backend.Config;

import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.Role;
import Com.Daily_Expenses_Tracker_Backend.Backend.Entity.UserEntity;
import Com.Daily_Expenses_Tracker_Backend.Backend.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@RequiredArgsConstructor
public class SuperAdminInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JdbcTemplate jdbcTemplate;

    @Value("${app.super-admin.enabled:true}")
    private boolean enabled;

    @Value("${app.super-admin.email}")
    private String email;

    @Value("${app.super-admin.username}")
    private String username;

    @Value("${app.super-admin.name}")
    private String name;

    @Value("${app.super-admin.password}")
    private String password;

    @Override
    public void run(String... args) {
        if (!enabled) {
            return;
        }

        jdbcTemplate.execute(
                "ALTER TABLE tbl_users MODIFY COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER'"
        );

        if (userRepository.findByEmail(email).isPresent()) {
            return;
        }

        UserEntity superAdmin = UserEntity.builder()
                .userId("SA-" + UUID.randomUUID())
                .name(name)
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(password))
                .isAccountVerified(true)
                .role(Role.SUPER_ADMIN)
                .build();

        userRepository.save(superAdmin);
    }
}