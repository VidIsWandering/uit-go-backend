package com.uitgo.tripservice.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
public class CacheConfig {
    @Bean
    public Caffeine<Object, Object> caffeineSpec() {
        return Caffeine.newBuilder()
                .recordStats()
                .expireAfterWrite(30, TimeUnit.SECONDS)
                .maximumSize(5000);
    }

    @Bean
    public CacheManager cacheManager(Caffeine<Object, Object> caffeine) {
        CaffeineCacheManager manager = new CaffeineCacheManager(
                "tripById", "availableTrips", "passengerHistory", "driverHistory", "driverEarnings"
        );
        manager.setCaffeine(caffeine);
        return manager;
    }
}