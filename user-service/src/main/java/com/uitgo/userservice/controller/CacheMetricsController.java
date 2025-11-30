package com.uitgo.userservice.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.cache.CacheManager;
import org.springframework.data.redis.cache.RedisCache;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/cache")
public class CacheMetricsController {
    private final CacheManager cacheManager;

    public CacheMetricsController(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> stats() {
        Map<String, Object> payload = new HashMap<>();
        org.springframework.cache.Cache usersCache = cacheManager.getCache("users");
        if (usersCache != null) {
            Map<String, Object> userStats = new HashMap<>();
            if (usersCache instanceof RedisCache) {
                userStats.put("type", "redis");
                userStats.put("name", usersCache.getName());
                // Redis doesn't expose hit/miss directly via Spring; metrics via Micrometer
                userStats.put("note", "See Prometheus /actuator/prometheus for cache.gets, cache.puts");
            } else {
                userStats.put("type", usersCache.getClass().getSimpleName());
                userStats.put("name", usersCache.getName());
            }
            payload.put("users", userStats);
        }
        return ResponseEntity.ok(payload);
    }
}
