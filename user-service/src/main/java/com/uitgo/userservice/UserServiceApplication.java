package com.uitgo.userservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class UserServiceApplication {
    public static void main(String[] args) {
        // Early diagnostic wrapper: print critical env info and ensure any
        // startup exception is printed unconditionally to stdout/stderr so
        // container logs capture the full stacktrace (helps debugging when
        // structured logging hides early failures).
        try {
            // Print a small, non-sensitive environment summary to help debug
            // common startup issues (DB, profiles, JWT). Do not print secrets
            // in full - only show presence and length.
            String dsUrl = System.getenv("SPRING_DATASOURCE_URL");
            String dsUser = System.getenv("SPRING_DATASOURCE_USERNAME");
            String dsPwd = System.getenv("SPRING_DATASOURCE_PASSWORD");
            String jwt = System.getenv("JWT_SECRET");
            String profiles = System.getenv("SPRING_PROFILES_ACTIVE");

            System.out.println("[startup-check] SPRING_PROFILES_ACTIVE=" + (profiles == null ? "<null>" : profiles));
            System.out.println("[startup-check] SPRING_DATASOURCE_URL=" + (dsUrl == null ? "<null>" : dsUrl));
            System.out.println("[startup-check] SPRING_DATASOURCE_USERNAME=" + (dsUser == null ? "<null>" : dsUser));
            System.out.println("[startup-check] SPRING_DATASOURCE_PASSWORD_PRESENT=" + (dsPwd != null && !dsPwd.isEmpty()));
            if (jwt == null) {
                System.out.println("[startup-check] JWT_SECRET_PRESENT=false");
            } else {
                System.out.println("[startup-check] JWT_SECRET_PRESENT=true; length=" + jwt.length() + " (showing first 4 chars)='" + jwt.substring(0, Math.min(4, jwt.length())) + "'");
            }

            SpringApplication.run(UserServiceApplication.class, args);
        } catch (Throwable t) {
            // Ensure full stacktrace is printed to both stdout and stderr so
            // Docker captures it regardless of logging configuration.
            System.err.println("[startup-fatal] Uncaught exception during startup:");
            t.printStackTrace(System.err);
            System.out.println("[startup-fatal] Uncaught exception during startup:");
            t.printStackTrace(System.out);
            // Rethrow or exit with non-zero to make failure obvious to orchestrators.
            System.exit(1);
        }
    }
}
