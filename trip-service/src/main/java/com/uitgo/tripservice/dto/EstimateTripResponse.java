package com.uitgo.tripservice.dto;

public class EstimateTripResponse {
    private double estimatedPrice;
    private int distanceMeters;

    public EstimateTripResponse() {}

    public EstimateTripResponse(double estimatedPrice, int distanceMeters) {
        this.estimatedPrice = estimatedPrice;
        this.distanceMeters = distanceMeters;
    }

    public double getEstimatedPrice() { return estimatedPrice; }
    public void setEstimatedPrice(double estimatedPrice) { this.estimatedPrice = estimatedPrice; }

    public int getDistanceMeters() { return distanceMeters; }
    public void setDistanceMeters(int distanceMeters) { this.distanceMeters = distanceMeters; }
}
