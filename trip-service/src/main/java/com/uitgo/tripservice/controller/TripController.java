package com.uitgo.tripservice.controller;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.uitgo.tripservice.dto.CreateTripRequest;
import com.uitgo.tripservice.dto.DriverLocationResponse;
import com.uitgo.tripservice.dto.EarningsResponse;
import com.uitgo.tripservice.dto.EstimateTripResponse;
import com.uitgo.tripservice.dto.LocationDTO;
import com.uitgo.tripservice.dto.RatingRequest;
import com.uitgo.tripservice.dto.TripDetailResponse;
import com.uitgo.tripservice.dto.TripHistoryResponse;
import com.uitgo.tripservice.dto.TripResponse;
import com.uitgo.tripservice.model.Location;
import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.model.TripStatus;
import com.uitgo.tripservice.service.DriverService;
import com.uitgo.tripservice.service.PricingService;
import com.uitgo.tripservice.service.TripService;

@RestController
@RequestMapping("/trips")
public class TripController {
    private final TripService tripService;
    private final PricingService pricingService;
    private final DriverService driverService;

    public TripController(TripService tripService, PricingService pricingService, DriverService driverService) {
        this.tripService = tripService;
        this.pricingService = pricingService;
        this.driverService = driverService;
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

    @GetMapping("/{id}")
    public ResponseEntity<TripDetailResponse> getTripDetail(@PathVariable("id") UUID tripId) {
        UUID userId = getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        Trip trip = tripService.getTripById(tripId)
                .orElseThrow(() -> new RuntimeException("Trip not found"));

        // Kiểm tra quyền truy cập (phải là passenger hoặc driver của chuyến đi)
        if (!trip.getPassengerId().equals(userId) && 
            (trip.getDriverId() == null || !trip.getDriverId().equals(userId))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        TripDetailResponse response = toDetailResponse(trip);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/accept")
    public ResponseEntity<TripResponse> acceptTrip(@PathVariable("id") UUID tripId) {
        UUID driverId = getCurrentUserId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            Trip trip = tripService.acceptTrip(tripId, driverId);
            return ResponseEntity.ok(toResponse(trip));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<Void> rejectTrip(@PathVariable("id") UUID tripId) {
        UUID driverId = getCurrentUserId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            tripService.rejectTrip(tripId, driverId);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/start")
    public ResponseEntity<TripResponse> startTrip(@PathVariable("id") UUID tripId) {
        UUID driverId = getCurrentUserId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            Trip trip = tripService.startTrip(tripId, driverId);
            return ResponseEntity.ok(toResponse(trip));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<TripResponse> completeTrip(@PathVariable("id") UUID tripId) {
        UUID driverId = getCurrentUserId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            Trip trip = tripService.completeTrip(tripId, driverId);
            return ResponseEntity.ok(toResponse(trip));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<TripResponse> cancelTrip(@PathVariable("id") UUID tripId) {
        UUID passengerId = getCurrentUserId();
        if (passengerId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            Trip trip = tripService.cancelTrip(tripId, passengerId);
            return ResponseEntity.ok(toResponse(trip));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/rating")
    public ResponseEntity<TripResponse> rateTrip(@PathVariable("id") UUID tripId, @RequestBody RatingRequest request) {
        UUID passengerId = getCurrentUserId();
        if (passengerId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            Trip trip = tripService.rateTrip(tripId, passengerId, request.getRating(), request.getComment());
            return ResponseEntity.ok(toResponse(trip));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{id}/driver-location")
    public ResponseEntity<DriverLocationResponse> getDriverLocation(@PathVariable("id") UUID tripId) {
        UUID passengerId = getCurrentUserId();
        if (passengerId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        Trip trip = tripService.getTripById(tripId)
                .orElseThrow(() -> new RuntimeException("Trip not found"));

        if (!trip.getPassengerId().equals(passengerId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        if (trip.getDriverId() == null) {
            return ResponseEntity.notFound().build();
        }

        // Gọi driver-service để lấy vị trí tài xế
        LocationDTO location = driverService.getDriverLocation(trip.getDriverId());
        DriverLocationResponse response = new DriverLocationResponse(trip.getDriverId(), location);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/available")
    public ResponseEntity<List<TripDetailResponse>> getAvailableTrips(@RequestParam(defaultValue = "5000") int radius) {
        UUID driverId = getCurrentUserId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Lấy vị trí tài xế hiện tại
        LocationDTO driverLoc = driverService.getDriverLocation(driverId);
        Location driverLocation = new Location(driverLoc.getLatitude(), driverLoc.getLongitude());

        List<Trip> availableTrips = tripService.getAvailableTrips(driverLocation, radius);
        List<TripDetailResponse> response = availableTrips.stream()
                .map(this::toDetailResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/passenger/{passengerId}/history")
    public ResponseEntity<TripHistoryResponse> getPassengerHistory(
            @PathVariable UUID passengerId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int limit) {
        
        UUID currentUserId = getCurrentUserId();
        if (currentUserId == null || !currentUserId.equals(passengerId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        TripStatus tripStatus = status != null ? TripStatus.valueOf(status) : null;
        Page<Trip> tripPage = tripService.getPassengerHistory(passengerId, tripStatus, page, limit);

        List<TripDetailResponse> trips = tripPage.getContent().stream()
                .map(this::toDetailResponse)
                .collect(Collectors.toList());

        TripHistoryResponse.PaginationInfo pagination = new TripHistoryResponse.PaginationInfo(
                page,
                tripPage.getTotalPages(),
                tripPage.getTotalElements()
        );

        TripHistoryResponse response = new TripHistoryResponse(trips, pagination);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/driver/{driverId}/history")
    public ResponseEntity<TripHistoryResponse> getDriverHistory(
            @PathVariable UUID driverId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int limit) {
        
        UUID currentUserId = getCurrentUserId();
        if (currentUserId == null || !currentUserId.equals(driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        TripStatus tripStatus = status != null ? TripStatus.valueOf(status) : null;
        Page<Trip> tripPage = tripService.getDriverHistory(driverId, tripStatus, page, limit);

        List<TripDetailResponse> trips = tripPage.getContent().stream()
                .map(this::toDetailResponse)
                .collect(Collectors.toList());

        TripHistoryResponse.PaginationInfo pagination = new TripHistoryResponse.PaginationInfo(
                page,
                tripPage.getTotalPages(),
                tripPage.getTotalElements()
        );

        TripHistoryResponse response = new TripHistoryResponse(trips, pagination);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/driver/{driverId}/earnings")
    public ResponseEntity<EarningsResponse> getDriverEarnings(
            @PathVariable UUID driverId,
            @RequestParam(defaultValue = "today") String period,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to) {
        
        UUID currentUserId = getCurrentUserId();
        if (currentUserId == null || !currentUserId.equals(driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        OffsetDateTime fromDate = from != null ? OffsetDateTime.parse(from, DateTimeFormatter.ISO_DATE_TIME) : null;
        OffsetDateTime toDate = to != null ? OffsetDateTime.parse(to, DateTimeFormatter.ISO_DATE_TIME) : null;

        TripService.EarningsData data = tripService.calculateEarnings(driverId, period, fromDate, toDate);

        EarningsResponse response = new EarningsResponse();
        response.setDriverId(driverId);
        response.setPeriod(period);
        response.setTotalTrips(data.totalTrips);
        response.setCompletedTrips(data.completedTrips);
        response.setCancelledTrips(data.cancelledTrips);
        response.setTotalEarnings(data.totalEarnings);
        response.setAverageEarningsPerTrip(data.averageEarningsPerTrip);
        response.setFrom(data.from);
        response.setTo(data.to);

        EarningsResponse.EarningsBreakdown breakdown = new EarningsResponse.EarningsBreakdown();
        breakdown.setTripFees(data.tripFees);
        breakdown.setBonuses(data.bonuses);
        breakdown.setTips(data.tips);
        breakdown.setCommission(data.commission);
        breakdown.setNetEarnings(data.netEarnings);
        response.setBreakdown(breakdown);

        return ResponseEntity.ok(response);
    }

    // Helper methods
    private UUID getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null) {
            return null;
        }
        try {
            return UUID.fromString(auth.getPrincipal().toString());
        } catch (IllegalArgumentException ex) {
            return null;
        }
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

    private TripDetailResponse toDetailResponse(Trip t) {
        TripDetailResponse resp = new TripDetailResponse();
        resp.setId(t.getId());
        resp.setPassengerId(t.getPassengerId());
        resp.setDriverId(t.getDriverId());
        resp.setOrigin(new LocationDTO(t.getOriginLatitude(), t.getOriginLongitude()));
        resp.setDestination(new LocationDTO(t.getDestinationLatitude(), t.getDestinationLongitude()));
        resp.setEstimatedPrice(t.getPrice());
        resp.setActualPrice(t.getPrice());
        resp.setDistanceMeters(t.getDistanceMeters());
        resp.setStatus(t.getStatus().name());
        resp.setRating(t.getRating());
        resp.setComment(t.getComment());
        resp.setCreatedAt(t.getCreatedAt());
        resp.setAcceptedAt(t.getAcceptedAt());
        resp.setStartedAt(t.getStartedAt());
        resp.setCompletedAt(t.getCompletedAt());
        resp.setCancelledAt(t.getCancelledAt());
        return resp;
    }
}
