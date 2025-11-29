package com.uitgo.tripservice.config;

import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;

/**
 * Routing DataSource: tách luồng đọc/ghi để sử dụng Primary vs Read Replica.
 * - Ghi (WRITE): dùng datasource primary (SPRING_DATASOURCE_URL)
 * - Đọc (READ): dùng datasource replica (SPRING_DATASOURCE_READ_URL)
 *
 * Cách sử dụng:
 * - Đối với các service/repository read-only, đánh dấu @Transactional(readOnly = true)
 *   -> Spring sẽ route sang READ datasource.
 */
@Configuration
public class DataSourceConfig {

    /**
     * URLs được cấp qua biến môi trường / properties.
     */
    @Value("${SPRING_DATASOURCE_URL}")
    private String writeUrl;

    @Value("${SPRING_DATASOURCE_USERNAME}")
    private String username;

    @Value("${SPRING_DATASOURCE_PASSWORD}")
    private String password;

    @Value("${SPRING_DATASOURCE_READ_URL:}")
    private String readUrl; // optional, nếu thiếu sẽ fallback sang write

    @Bean(name = "writeDataSource")
    public DataSource writeDataSource() {
        return DataSourceBuilder.create()
                .url(writeUrl)
                .username(username)
                .password(password)
                .driverClassName("org.postgresql.Driver")
                .build();
    }

    @Bean(name = "readDataSource")
    public DataSource readDataSource() {
        String targetReadUrl = (readUrl == null || readUrl.isBlank()) ? writeUrl : readUrl;
        return DataSourceBuilder.create()
                .url(targetReadUrl)
                .username(username)
                .password(password)
                .driverClassName("org.postgresql.Driver")
                .build();
    }

    @Bean
    public DataSource routingDataSource(
            @Qualifier("writeDataSource") DataSource writeDS,
            @Qualifier("readDataSource") DataSource readDS) {
        ReplicationRoutingDataSource routing = new ReplicationRoutingDataSource();
        Map<Object, Object> targetDataSources = new HashMap<>();
        targetDataSources.put(DataSourceType.WRITE, writeDS);
        targetDataSources.put(DataSourceType.READ, readDS);
        routing.setTargetDataSources(targetDataSources);
        routing.setDefaultTargetDataSource(writeDS);
        return routing;
    }

    @Bean
    public DataSource dataSource(@Qualifier("routingDataSource") DataSource routing) {
        // Expose routing datasource as primary DataSource bean
        return routing;
    }

    /**
     * Enum chỉ định loại datasource.
     */
    public enum DataSourceType { WRITE, READ }

    /**
     * Routing dựa trên transactional context.
     * Nếu @Transactional(readOnly = true) -> READ, ngược lại -> WRITE.
     */
    static class ReplicationRoutingDataSource extends AbstractRoutingDataSource {
        @Override
        protected Object determineCurrentLookupKey() {
            // Spring sẽ set readOnly flag trên TransactionSynchronizationManager
            boolean readOnly = org.springframework.transaction.support.TransactionSynchronizationManager
                    .isCurrentTransactionReadOnly();
            return readOnly ? DataSourceType.READ : DataSourceType.WRITE;
        }
    }
}
