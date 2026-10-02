package Com.Daily_Expenses_Tracker_Backend.Backend.Util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Component
public class JwtUtil {

    @Value("${jwt.secret.key}")
    private String SECRET_KEY;

    // Generate a JWT token for the authenticated user
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();

        return createToken(claims, userDetails.getUsername());
    }

    // Create and sign the JWT token
    private String createToken(Map<String, Object> claims, String email) {
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(email)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(
                        new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 10)
                ) // Token expires after 10 hours
                .signWith(SignatureAlgorithm.HS256, SECRET_KEY)
                .compact();
    }

    // Extract all claims from the signed JWT
    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .setSigningKey(SECRET_KEY)
                .parseClaimsJws(token)  // Correct parser for signed JWT
                .getBody();
    }

    // Extract a specific claim from the JWT
    public <T> T extractClaims(
            String token,
            Function<Claims, T> claimsResolver
    ) {
        final Claims claims = extractAllClaims(token);

        return claimsResolver.apply(claims);
    }

    // Extract the user's email from the JWT subject
    public String extractEmail(String token) {
        return extractClaims(token, Claims::getSubject);
    }

    // Extract the token expiration date
    public Date extractExpiration(String token) {
        return extractClaims(token, Claims::getExpiration);
    }

    // Check whether the JWT has expired
    private Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    // Validate the JWT against the authenticated user's details
    public Boolean validateToken(
            String token,
            UserDetails userDetails
    ) {
        final String email = extractEmail(token);

        return email.equals(userDetails.getUsername())
                && !isTokenExpired(token);
    }
}