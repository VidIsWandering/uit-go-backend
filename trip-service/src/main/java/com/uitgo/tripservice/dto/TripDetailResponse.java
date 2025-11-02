package com.uitgo.tripservice.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TripDetailResponse {
    @JsonProperty("id")
    private UUID id;

    @JsonProperty("passengerId")
    private UUID passengerId;

    @JsonProperty("driverId")
    private UUID driverId;

    @JsonProperty("origin")
    private LocationDTO origin;

    @JsonProperty("destination")
    private LocationDTO destination;

    @JsonProperty("estimatedPrice")
    private Double estimatedPrice;

    @JsonProperty("actualPrice")
    private Double actualPrice;

    @JsonProperty("distanceMeters")
    private Integer distanceMeters;

    @JsonProperty("status")
    private String status;

    @JsonProperty("rating")
    private Integer rating;

    @JsonProperty("comment")
    private String comment;

    @JsonProperty("createdAt")
    private OffsetDateTime createdAt;

    @JsonProperty("acceptedAt")
    private OffsetDateTime acceptedAt;

    @JsonProperty("startedAt")
    private OffsetDateTime startedAt;

    @JsonProperty("completedAt")
    private OffsetDateTime completedAt;

    @JsonProperty("cancelledAt")
    private OffsetDateTime cancelledAt;

    public TripDetailResponse() {}

    // Getters and setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getPassengerId() { return passengerId; }
    public void setPassengerId(UUID passengerId) { this.passengerId = passengerId; }

    public UUID getDriverId() { return driverId; }
    public void setDriverId(UUID driverId) { this.driverId = driverId; }

    public LocationDTO getOrigin() { return origin; }
    public void setOrigin(LocationDTO origin) { this.origin = origin; }

    public LocationDTO getDestination() { return destination; }
    public void setDestination(LocationDTO destination) { this.destination = destination; }

    public Double getEstimatedPrice() { return estimatedPrice; }
    public void setEstimatedPrice(Double estimatedPrice) { this.estimatedPrice = estimatedPrice; }

    public Double getActualPrice() { return actualPrice; }
    public void setActualPrice(Double actualPrice) { this.actualPrice = actualPrice; }

    public Integer getDistanceMeters() { return distanceMeters; }
    public void setDistanceMeters(Integer distanceMeters) { this.distanceMeters = distanceMeters; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }

    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(OffsetDateTime acceptedAt) { this.acceptedAt = acceptedAt; }

    public OffsetDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(OffsetDateTime startedAt) { this.startedAt = startedAt; }

    public OffsetDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }

    public OffsetDateTime getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(OffsetDateTime cancelledAt) { this.cancelledAt = cancelledAt; }
}
