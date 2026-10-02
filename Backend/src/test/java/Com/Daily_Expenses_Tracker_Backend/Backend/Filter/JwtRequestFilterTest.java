package Com.Daily_Expenses_Tracker_Backend.Backend.Filter;

import Com.Daily_Expenses_Tracker_Backend.Backend.Service.AppUserDetailsService;
import Com.Daily_Expenses_Tracker_Backend.Backend.Util.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JwtRequestFilterTest {

    @Mock
    private AppUserDetailsService appUserDetailsService;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private JwtRequestFilter jwtRequestFilter;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void shouldAuthenticateWhenAuthorizationHeaderUsesLowercaseBearerPrefix() throws Exception {
        String token = "jwt-token";
        String email = "user@example.com";
        var userDetails = User.withUsername(email)
                .password("secret")
                .authorities("ROLE_USER")
                .build();

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader(HttpHeaders.AUTHORIZATION, "bearer " + token);
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain filterChain = new MockFilterChain();

        when(jwtUtil.extractEmail(token)).thenReturn(email);
        when(appUserDetailsService.loadUserByUsername(email)).thenReturn(userDetails);
        when(jwtUtil.validateToken(token, userDetails)).thenReturn(true);

        jwtRequestFilter.doFilter(request, response, filterChain);

        assertNotNull(SecurityContextHolder.getContext().getAuthentication());
        assertEquals(email, SecurityContextHolder.getContext().getAuthentication().getName());
    }
}
