package Com.Daily_Expenses_Tracker_Backend.Backend.Filter;

import Com.Daily_Expenses_Tracker_Backend.Backend.Service.AppUserDetailsService;
import Com.Daily_Expenses_Tracker_Backend.Backend.Util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtRequestFilter extends OncePerRequestFilter {

    private final AppUserDetailsService appUserDetailsService;
    private final JwtUtil jwtUtil;

    private static final List<String> PUBLIC_URLS = List.of(
            "/login",
            "/google",
            "/register",
            "/send-reset-otp",
            "/send-otp",
            "/reset-password",
            "/logout",
            "/admin/login"
    );

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // ==========================================
        // 1. Allow CORS preflight requests
        // ==========================================

        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        // ==========================================
        // 2. Get request path
        // ==========================================

        String path = request.getServletPath();

        // ==========================================
        // 3. Allow public URLs
        // ==========================================

        if (PUBLIC_URLS.contains(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        String jwt = null;
        String email = null;

        // ==========================================
        // 4. Check Authorization header
        // ==========================================

        final String authorizationHeader =
                request.getHeader("Authorization");

        if (authorizationHeader != null
        && authorizationHeader.regionMatches(true, 0, "Bearer ", 0, 7)) {
            jwt = authorizationHeader.substring(7);
        }

        // ==========================================
        // 5. If no header token, check cookie
        // ==========================================

        if (jwt == null) {

            Cookie[] cookies = request.getCookies();

            if (cookies != null) {

                for (Cookie cookie : cookies) {

                    if ("jwt".equals(cookie.getName())) {

                        jwt = cookie.getValue();
                        break;
                    }
                }
            }
        }

        // ==========================================
        // 6. Validate JWT
        // ==========================================

        if (jwt != null) {

            email = jwtUtil.extractEmail(jwt);

            if (email != null
                    && SecurityContextHolder
                    .getContext()
                    .getAuthentication() == null) {

                UserDetails userDetails =
                        appUserDetailsService
                                .loadUserByUsername(email);

                if (jwtUtil.validateToken(jwt, userDetails)) {

                    UsernamePasswordAuthenticationToken
                            authenticationToken =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails,
                                    null,
                                    userDetails.getAuthorities()
                            );

                    authenticationToken.setDetails(
                            new WebAuthenticationDetailsSource()
                                    .buildDetails(request)
                    );

                    SecurityContextHolder
                            .getContext()
                            .setAuthentication(
                                    authenticationToken
                            );
                }
            }
        }

        // ==========================================
        // 7. Continue filter chain
        // ==========================================

        filterChain.doFilter(request, response);
    }
}
