import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import javax.crypto.SecretKey;

public class GenerateJwt {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java GenerateJwt <userId>");
            System.exit(1);
        }
        
        String userId = args[0];
        String secret = System.getenv("JWT_SECRET");
        if (secret == null || secret.isBlank()) {
            System.err.println("JWT_SECRET environment variable not set");
            System.exit(1);
        }
        
        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        
        // Token valid for 24 hours
        long now = System.currentTimeMillis();
        long exp = now + (24 * 60 * 60 * 1000);
        
        String token = Jwts.builder()
            .setSubject(userId)
            .setIssuedAt(new Date(now))
            .setExpiration(new Date(exp))
            .signWith(key, SignatureAlgorithm.HS256)
            .compact();
        
        System.out.println(token);
    }
}
