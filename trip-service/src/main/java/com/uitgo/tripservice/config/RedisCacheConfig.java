package com.uitgo.tripservice.config;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;

@Configuration
@EnableCaching
public class RedisCacheConfig {

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        // Default cache configuration
        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofSeconds(60))
                .serializeValuesWith(
                        RedisSerializationContext.SerializationPair.fromSerializer(
                                new GenericJackson2JsonRedisSerializer()
                        )
                );

        // Custom TTL for specific caches
        Map<String, RedisCacheConfiguration> cacheConfigurations = new HashMap<>();
        
        // Trip by ID cache (60s TTL)
        cacheConfigurations.put("trips", 
                defaultConfig.entryTtl(Duration.ofSeconds(60)));
        
        // Trips by passenger cache (30s TTL - more volatile)
        cacheConfigurations.put("tripsByPassenger", 
                defaultConfig.entryTtl(Duration.ofSeconds(30)));
        
        // Trips by driver cache (30s TTL - more volatile)
        cacheConfigurations.put("tripsByDriver", 
                defaultConfig.entryTtl(Duration.ofSeconds(30)));

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(defaultConfig)
                .withInitialCacheConfigurations(cacheConfigurations)
                .build();
    }
}
