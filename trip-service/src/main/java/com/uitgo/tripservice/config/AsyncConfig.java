package com.uitgo.tripservice.config;

import java.util.concurrent.Executor;
import java.util.concurrent.ThreadPoolExecutor;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * Async configuration for non-blocking SQS operations.
 * 
 * CRITICAL: Dedicated executor prevents default thread pool saturation
 * when SQS has latency spikes (400-700ms).
 */
@EnableAsync
@Configuration
public class AsyncConfig {

    /**
     * Dedicated thread pool for SQS message sending.
     * 
     * Sizing rationale:
     * - Core pool: 10 threads (handles baseline load)
     * - Max pool: 50 threads (handles peak load with SQS latency spikes)
     * - Queue capacity: 500 (buffers requests during SQS slow periods)
     * - Rejected execution: CallerRunsPolicy (apply backpressure gracefully)
     * 
     * Expected throughput:
     * - At 100ms SQS latency: 10 threads × (1000ms / 100ms) = 100 msg/s
     * - At 400ms SQS latency: 50 threads × (1000ms / 400ms) = 125 msg/s
     * - Queue absorbs 500 requests during transient spikes
     */
    @Bean("sqsExecutor")
    public Executor sqsExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(50);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("sqs-async-");
        executor.setKeepAliveSeconds(60);
        
        // Apply backpressure when queue full: use caller thread as fallback
        // This prevents OOM and provides natural rate limiting
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        
        executor.initialize();
        return executor;
    }
}
