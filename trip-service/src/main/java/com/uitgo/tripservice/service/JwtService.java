package com.uitgo.tripservice.service;

import java.nio.charset.StandardCharsets;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {
    private static final int MIN_SECRET_LENGTH = 32;

    private final String secret;
    private final SecretKey key;

    public JwtService(@Value("${jwt.secret:#{null}}") String jwtSecret) {
        // Allow configuration via Spring property (jwt.secret) or environment variable (JWT_SECRET)
        String env = jwtSecret;
        if (env == null || env.isBlank()) {
            env = System.getenv("JWT_SECRET");
        }
        if (env == null || env.isBlank()) {
            throw new IllegalStateException(
                "JWT_SECRET environment variable or jwt.secret property is not set. This is required for secure operation. " +
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

    public SecretKey getSigningKey() { return key; }
}
