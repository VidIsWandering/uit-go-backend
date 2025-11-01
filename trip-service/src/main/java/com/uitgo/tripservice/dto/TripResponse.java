package com.uitgo.tripservice.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TripResponse {
    @JsonProperty("id")
    private UUID id;
    @JsonProperty("passengerId")
    private UUID passengerId;
    @JsonProperty("driverId")
    private UUID driverId;
    @JsonProperty("status")
    private String status;
    @JsonProperty("createdAt")
    private OffsetDateTime createdAt;

    public TripResponse() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getPassengerId() { return passengerId; }
    public void setPassengerId(UUID passengerId) { this.passengerId = passengerId; }

    public UUID getDriverId() { return driverId; }
    public void setDriverId(UUID driverId) { this.driverId = driverId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
