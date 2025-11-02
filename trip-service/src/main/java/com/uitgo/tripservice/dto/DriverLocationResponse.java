package com.uitgo.tripservice.dto;

import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;

public class DriverLocationResponse {
    @JsonProperty("driver_id")
    private UUID driverId;

    @JsonProperty("location")
    private LocationDTO location;

    public DriverLocationResponse() {}

    public DriverLocationResponse(UUID driverId, LocationDTO location) {
        this.driverId = driverId;
        this.location = location;
    }

    public UUID getDriverId() {
        return driverId;
    }

    public void setDriverId(UUID driverId) {
        this.driverId = driverId;
    }

    public LocationDTO getLocation() {
        return location;
    }

    public void setLocation(LocationDTO location) {
        this.location = location;
    }
}
