package com.uitgo.tripservice.integration;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.model.TripStatus;
import com.uitgo.tripservice.repository.TripRepository;

@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
public class TripRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        registry.add("spring.jpa.properties.hibernate.dialect", () -> "org.hibernate.dialect.PostgreSQLDialect");
    }

    @Autowired
    private TripRepository tripRepository;

    @Test
    void shouldSaveAndRetrieveTrip() {
        // Given
        Trip trip = new Trip();
        trip.setPassengerId(UUID.randomUUID());
        trip.setStatus(TripStatus.FINDING_DRIVER);
        trip.setOriginLatitude(10.762622);
        trip.setOriginLongitude(106.660172);
        trip.setDestinationLatitude(10.852622);
        trip.setDestinationLongitude(106.770172);

        // When
        Trip savedTrip = tripRepository.save(trip);

        // Then
        assertThat(savedTrip.getId()).isNotNull();
        assertThat(savedTrip.getPassengerId()).isNotNull();
        assertThat(savedTrip.getStatus()).isEqualTo(TripStatus.FINDING_DRIVER);
        assertThat(savedTrip.getCreatedAt()).isNotNull();
        assertThat(savedTrip.getUpdatedAt()).isNotNull();
    }
}
