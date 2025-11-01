package com.uitgo.tripservice.dto;

public class CreateTripRequest {
    private LocationDTO origin;
    private LocationDTO destination;

    public CreateTripRequest() {}

    public LocationDTO getOrigin() { return origin; }
    public void setOrigin(LocationDTO origin) { this.origin = origin; }

    public LocationDTO getDestination() { return destination; }
    public void setDestination(LocationDTO destination) { this.destination = destination; }
}
