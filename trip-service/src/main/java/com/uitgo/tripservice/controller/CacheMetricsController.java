package com.uitgo.tripservice.controller;

import com.github.benmanes.caffeine.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

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
        for (String name : new String[]{"tripById", "availableTrips", "passengerHistory", "driverHistory", "driverEarnings"}) {
            org.springframework.cache.Cache springCache = cacheManager.getCache(name);
            if (springCache == null) continue;
            Object nativeCache = springCache.getNativeCache();
            Map<String, Object> entry = new HashMap<>();
            if (nativeCache instanceof Cache) {
                Cache<?, ?> caffeine = (Cache<?, ?>) nativeCache;
                entry.put("estimatedSize", caffeine.estimatedSize());
                entry.put("hitCount", caffeine.stats().hitCount());
                entry.put("missCount", caffeine.stats().missCount());
                entry.put("loadSuccessCount", caffeine.stats().loadSuccessCount());
                entry.put("loadFailureCount", caffeine.stats().loadFailureCount());
                entry.put("evictionCount", caffeine.stats().evictionCount());
            }
            payload.put(name, entry);
        }
        return ResponseEntity.ok(payload);
    }
}