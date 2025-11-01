package com.uitgo.tripservice.service;

import java.util.UUID;

import javax.transaction.Transactional;

import org.springframework.stereotype.Service;

import com.uitgo.tripservice.model.Location;
import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.model.TripStatus;
import com.uitgo.tripservice.repository.TripRepository;

@Service
public class TripService {
    private final TripRepository tripRepository;
    private final PricingService pricingService;

    public TripService(TripRepository tripRepository, PricingService pricingService) {
        this.tripRepository = tripRepository;
        this.pricingService = pricingService;
    }

    @Transactional
    public Trip createTrip(UUID passengerId, Location origin, Location destination) {
        Trip trip = new Trip();
        trip.setPassengerId(passengerId);
        trip.setStatus(TripStatus.FINDING_DRIVER);
        trip.setOriginLatitude(origin.getLatitude());
        trip.setOriginLongitude(origin.getLongitude());
        trip.setDestinationLatitude(destination.getLatitude());
        trip.setDestinationLongitude(destination.getLongitude());
        int distance = pricingService.calculateDistanceMeters(origin, destination);
        double price = pricingService.calculatePrice(origin, destination);
        trip.setDistanceMeters(distance);
        trip.setPrice(price);
        return tripRepository.save(trip);
    }
}
