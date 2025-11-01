package com.uitgo.tripservice.controller;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.uitgo.tripservice.dto.CreateTripRequest;
import com.uitgo.tripservice.dto.EstimateTripResponse;
import com.uitgo.tripservice.dto.LocationDTO;
import com.uitgo.tripservice.dto.TripResponse;
import com.uitgo.tripservice.model.Location;
import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.service.PricingService;
import com.uitgo.tripservice.service.TripService;

@RestController
@RequestMapping("/trips")
public class TripController {
    private final TripService tripService;
    private final PricingService pricingService;

    public TripController(TripService tripService, PricingService pricingService) {
        this.tripService = tripService;
        this.pricingService = pricingService;
    }

    @PostMapping
    public ResponseEntity<TripResponse> create(@RequestBody CreateTripRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        UUID passengerId;
        try {
            passengerId = UUID.fromString(auth.getPrincipal().toString());
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        Location origin = request.getOrigin().toLocation();
        Location destination = request.getDestination().toLocation();
        Trip created = tripService.createTrip(passengerId, origin, destination);
        TripResponse resp = toResponse(created);
        return ResponseEntity.status(HttpStatus.CREATED).body(resp);
    }

    @PostMapping("/estimate")
    public EstimateTripResponse estimate(@RequestBody CreateTripRequest request) {
        Location origin = toLoc(request.getOrigin());
        Location destination = toLoc(request.getDestination());
        int distance = pricingService.calculateDistanceMeters(origin, destination);
        double price = pricingService.calculatePrice(origin, destination);
        return new EstimateTripResponse(price, distance);
    }

    private static Location toLoc(LocationDTO dto) {
        return new Location(dto.getLatitude(), dto.getLongitude());
    }

    private static TripResponse toResponse(Trip t) {
        TripResponse resp = new TripResponse();
        resp.setId(t.getId());
        resp.setPassengerId(t.getPassengerId());
        resp.setDriverId(t.getDriverId());
        resp.setStatus(t.getStatus().name());
        resp.setCreatedAt(t.getCreatedAt());
        return resp;
    }
}
