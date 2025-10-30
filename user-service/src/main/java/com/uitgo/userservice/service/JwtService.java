package com.uitgo.userservice.service;

import java.nio.charset.StandardCharsets;
import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.stereotype.Service;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {
    private static final int MIN_SECRET_LENGTH = 32; // minimum length for HMAC-SHA256

    private final String secret;
    private final SecretKey key;

    public JwtService() {
        String env = System.getenv("JWT_SECRET");
        if (env == null || env.isBlank()) {
            throw new IllegalStateException(
                "JWT_SECRET environment variable is not set. This is required for secure operation. " +
                "Set JWT_SECRET to a strong secret of at least " + MIN_SECRET_LENGTH + " characters."
            );
        }
        if (env.length() < MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                "JWT_SECRET is too short. For security, it must be at least " + 
                MIN_SECRET_LENGTH + " characters long (provided: " + env.length() + ")."
            );
        }
        secret = env;
        key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(String userId, String email) {
        return Jwts.builder()
                .setSubject(userId)
                .claim("email", email)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24)) // 24h
                .signWith(key)
                .compact();
    }

    public SecretKey getSigningKey() { return key; }
}
