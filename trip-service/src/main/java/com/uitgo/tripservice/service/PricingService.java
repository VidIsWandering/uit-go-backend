package com.uitgo.tripservice.service;

import org.springframework.stereotype.Service;

import com.uitgo.tripservice.model.Location;

@Service
public class PricingService {
    private static final double BASE_FARE = 10000.0; // VND
    private static final double PER_KM = 8000.0;     // VND per km

    public int calculateDistanceMeters(Location origin, Location destination) {
        return (int) Math.round(origin.distanceTo(destination));
    }

    public double calculatePrice(Location origin, Location destination) {
        int meters = calculateDistanceMeters(origin, destination);
        double km = meters / 1000.0;
        return Math.round((BASE_FARE + PER_KM * km) * 100.0) / 100.0;
    }
}
