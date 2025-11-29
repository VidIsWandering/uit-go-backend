package com.uitgo.tripservice.config;

import java.util.HashMap;
import java.util.Map;

import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;

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
                .driverClassName("com.p6spy.engine.spy.P6SpyDriver")
                .build();
    }

    @Bean(name = "readDataSource")
    public DataSource readDataSource() {
        String targetReadUrl = (readUrl == null || readUrl.isBlank()) ? writeUrl : readUrl;
        return DataSourceBuilder.create()
                .url(targetReadUrl)
                .username(username)
                .password(password)
                .driverClassName("com.p6spy.engine.spy.P6SpyDriver")
                .build();
    }

    @Bean(name = "routingDataSource")
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

    @Primary
    @Bean
    public DataSource dataSource(@Qualifier("routingDataSource") DataSource routing) {
        // Expose routing datasource as primary DataSource bean
        return routing;
    }

    @Primary
    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(
            @Qualifier("dataSource") DataSource dataSource) {
        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        em.setDataSource(dataSource);
        em.setPackagesToScan("com.uitgo.tripservice.model");

        HibernateJpaVendorAdapter vendorAdapter = new HibernateJpaVendorAdapter();
        vendorAdapter.setGenerateDdl(false);
        vendorAdapter.setShowSql(false);
        vendorAdapter.setDatabasePlatform("org.hibernate.dialect.PostgreSQLDialect");
        em.setJpaVendorAdapter(vendorAdapter);

        return em;
    }

    @Primary
    @Bean
    public PlatformTransactionManager transactionManager(EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
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
