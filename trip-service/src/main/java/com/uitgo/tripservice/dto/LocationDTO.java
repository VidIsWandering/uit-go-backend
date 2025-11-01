package com.uitgo.tripservice.dto;

import com.uitgo.tripservice.model.Location;

public class LocationDTO {
    private double latitude;
    private double longitude;

    public LocationDTO() {}

    public LocationDTO(double latitude, double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }

    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }

    public Location toLocation() { return new Location(latitude, longitude); }

    public static LocationDTO from(Location loc) {
        return new LocationDTO(loc.getLatitude(), loc.getLongitude());
    }
}
