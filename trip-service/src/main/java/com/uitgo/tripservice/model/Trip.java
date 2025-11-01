package com.uitgo.tripservice.model;

import java.time.OffsetDateTime;
import java.util.UUID;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.persistence.Id;
import javax.persistence.PrePersist;
import javax.persistence.PreUpdate;
import javax.persistence.Table;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

@Entity
@Table(name = "trips")
public class Trip {

    @Id
    @Column(name = "id", nullable = false, updatable = false, columnDefinition = "uuid")
    private UUID id = UUID.randomUUID();

    @Column(name = "passenger_id", nullable = false, columnDefinition = "uuid")
    private UUID passengerId;

    @Column(name = "driver_id", columnDefinition = "uuid")
    private UUID driverId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private TripStatus status = TripStatus.FINDING_DRIVER;

    @Column(name = "origin_latitude", nullable = false)
    private double originLatitude;

    @Column(name = "origin_longitude", nullable = false)
    private double originLongitude;

    @Column(name = "destination_latitude", nullable = false)
    private double destinationLatitude;

    @Column(name = "destination_longitude", nullable = false)
    private double destinationLongitude;

    @Column(name = "distance_meters")
    private Integer distanceMeters;

    @Column(name = "price")
    private Double price;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    public Trip() {}

    // Getters and setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getPassengerId() { return passengerId; }
    public void setPassengerId(UUID passengerId) { this.passengerId = passengerId; }

    public UUID getDriverId() { return driverId; }
    public void setDriverId(UUID driverId) { this.driverId = driverId; }

    public TripStatus getStatus() { return status; }
    public void setStatus(TripStatus status) { this.status = status; }

    public double getOriginLatitude() { return originLatitude; }
    public void setOriginLatitude(double originLatitude) { this.originLatitude = originLatitude; }

    public double getOriginLongitude() { return originLongitude; }
    public void setOriginLongitude(double originLongitude) { this.originLongitude = originLongitude; }

    public double getDestinationLatitude() { return destinationLatitude; }
    public void setDestinationLatitude(double destinationLatitude) { this.destinationLatitude = destinationLatitude; }

    public double getDestinationLongitude() { return destinationLongitude; }
    public void setDestinationLongitude(double destinationLongitude) { this.destinationLongitude = destinationLongitude; }

    public Integer getDistanceMeters() { return distanceMeters; }
    public void setDistanceMeters(Integer distanceMeters) { this.distanceMeters = distanceMeters; }

    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
        if (status == null) status = TripStatus.FINDING_DRIVER;
        if (id == null) id = UUID.randomUUID();
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
