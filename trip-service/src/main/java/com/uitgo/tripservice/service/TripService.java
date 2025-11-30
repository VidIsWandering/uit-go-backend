package com.uitgo.tripservice.service;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

import javax.persistence.OptimisticLockException;
import javax.transaction.Transactional;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.uitgo.tripservice.exception.TripConcurrentUpdateException;
import com.uitgo.tripservice.model.Location;
import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.model.TripStatus;
import com.uitgo.tripservice.repository.TripRepository;

import io.awspring.cloud.messaging.core.QueueMessagingTemplate;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

@Service
public class TripService {
    private final TripRepository tripRepository;
    private final PricingService pricingService;
    private final QueueMessagingTemplate queueMessagingTemplate;
    private final MeterRegistry meterRegistry;

    @Value("${sqs.queue.url}")
    private String queueUrl;

    public TripService(TripRepository tripRepository,
                       PricingService pricingService,
                       QueueMessagingTemplate queueMessagingTemplate,
                       MeterRegistry meterRegistry) {
        this.tripRepository = tripRepository;
        this.pricingService = pricingService;
        this.queueMessagingTemplate = queueMessagingTemplate;
        this.meterRegistry = meterRegistry;
    }

    @Transactional
    public Trip createTrip(UUID passengerId, Location origin, Location destination) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
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
            Trip savedTrip = tripRepository.save(trip);

            Map<String, Object> message = new HashMap<>();
            message.put("tripId", savedTrip.getId());
            message.put("passengerId", savedTrip.getPassengerId());
            message.put("origin", origin);
            message.put("destination", destination);
            message.put("distance", savedTrip.getDistanceMeters());
            message.put("price", savedTrip.getPrice());
            queueMessagingTemplate.convertAndSend(queueUrl, message);

            return savedTrip;
        } finally {
            sample.stop(meterRegistry.timer("trip.create.db_and_enqueue"));
        }
    }

    // Async enqueue only: create lightweight trip shell and push to queue immediately
    @Transactional
    public UUID enqueueTrip(UUID passengerId, Location origin, Location destination) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            Trip trip = new Trip();
            trip.setPassengerId(passengerId);
            trip.setStatus(TripStatus.FINDING_DRIVER);
            trip.setOriginLatitude(origin.getLatitude());
            trip.setOriginLongitude(origin.getLongitude());
            trip.setDestinationLatitude(destination.getLatitude());
            trip.setDestinationLongitude(destination.getLongitude());
            Trip savedTrip = tripRepository.save(trip);

            Map<String, Object> message = new HashMap<>();
            message.put("tripId", savedTrip.getId());
            message.put("passengerId", passengerId);
            message.put("origin", origin);
            message.put("destination", destination);
            queueMessagingTemplate.convertAndSend(queueUrl, message);
            return savedTrip.getId();
        } finally {
            sample.stop(meterRegistry.timer("trip.enqueue.latency"));
        }
    }

    @Cacheable(value = "trips", key = "#tripId")
    public Optional<Trip> getTripById(UUID tripId) {
        return tripRepository.findById(Objects.requireNonNull(tripId));
    }

    @Transactional
    @CacheEvict(value = {"trips", "tripsByDriver", "tripsByPassenger", "driverEarnings"}, allEntries = true)
    public Trip acceptTrip(UUID tripId, UUID driverId) {
        try {
            Trip trip = tripRepository.findById(Objects.requireNonNull(tripId))
                    .orElseThrow(() -> new RuntimeException("Trip not found"));
            
            if (trip.getStatus() != TripStatus.FINDING_DRIVER) {
                throw new RuntimeException("Trip is not available for acceptance");
            }
            
            trip.setDriverId(driverId);
            trip.setStatus(TripStatus.DRIVER_ACCEPTED);
            trip.setAcceptedAt(OffsetDateTime.now(ZoneOffset.UTC));
            return tripRepository.save(trip);
        } catch (OptimisticLockException e) {
            throw new TripConcurrentUpdateException("Chuyến đi đã được tài xế khác nhận. Vui lòng chọn chuyến khác.", e);
        }
    }

    @Transactional
    @CacheEvict(value = {"trips", "tripsByDriver", "tripsByPassenger"}, allEntries = true)
    public void rejectTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(Objects.requireNonNull(tripId))
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (trip.getStatus() != TripStatus.FINDING_DRIVER) {
            throw new RuntimeException("Trip is not available for rejection");
        }
        
        // Logic: Trong thực tế, có thể cần tìm tài xế khác
        // Ở đây chúng ta chỉ giữ nguyên trạng thái FINDING_DRIVER
    }

    @Transactional
    @CacheEvict(value = {"trips", "tripsByDriver", "tripsByPassenger"}, allEntries = true)
    public Trip startTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(Objects.requireNonNull(tripId))
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getDriverId().equals(driverId)) {
            throw new RuntimeException("You are not assigned to this trip");
        }
        
        if (trip.getStatus() != TripStatus.DRIVER_ACCEPTED) {
            throw new RuntimeException("Trip cannot be started in current status");
        }
        
        trip.setStatus(TripStatus.IN_PROGRESS);
        trip.setStartedAt(OffsetDateTime.now(ZoneOffset.UTC));
        return tripRepository.save(trip);
    }

    @Transactional
    @CacheEvict(value = {"trips", "tripsByDriver", "tripsByPassenger", "driverEarnings"}, allEntries = true)
    public Trip completeTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(Objects.requireNonNull(tripId))
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getDriverId().equals(driverId)) {
            throw new RuntimeException("You are not assigned to this trip");
        }
        
        if (trip.getStatus() != TripStatus.IN_PROGRESS) {
            throw new RuntimeException("Trip is not in progress");
        }
        
        trip.setStatus(TripStatus.COMPLETED);
        trip.setCompletedAt(OffsetDateTime.now(ZoneOffset.UTC));
        return tripRepository.save(trip);
    }

    @Transactional
    @CacheEvict(value = {"trips", "tripsByDriver", "tripsByPassenger", "driverEarnings"}, allEntries = true)
    public Trip cancelTrip(UUID tripId, UUID passengerId) {
        Trip trip = tripRepository.findById(Objects.requireNonNull(tripId))
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getPassengerId().equals(passengerId)) {
            throw new RuntimeException("You are not the passenger of this trip");
        }
        
        if (trip.getStatus() == TripStatus.COMPLETED || trip.getStatus() == TripStatus.CANCELLED) {
            throw new RuntimeException("Trip cannot be cancelled");
        }
        
        trip.setStatus(TripStatus.CANCELLED);
        trip.setCancelledAt(OffsetDateTime.now(ZoneOffset.UTC));
        return tripRepository.save(trip);
    }

    @Transactional
    @CacheEvict(value = {"trips", "tripsByDriver", "tripsByPassenger"}, allEntries = true)
    public Trip rateTrip(UUID tripId, UUID passengerId, int rating, String comment) {
        Trip trip = tripRepository.findById(Objects.requireNonNull(tripId))
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getPassengerId().equals(passengerId)) {
            throw new RuntimeException("You are not the passenger of this trip");
        }
        
        if (trip.getStatus() != TripStatus.COMPLETED) {
            throw new RuntimeException("Trip must be completed before rating");
        }
        
        if (rating < 1 || rating > 5) {
            throw new RuntimeException("Rating must be between 1 and 5");
        }
        
        trip.setRating(rating);
        trip.setComment(comment);
        return tripRepository.save(trip);
    }

    @Cacheable(value = "availableTrips", key = "#radiusMeters")
    public List<Trip> getAvailableTrips(Location driverLocation, int radiusMeters) {
        // Lấy các chuyến đi đang chờ tài xế
        // Trong thực tế, nên dùng spatial query để tìm trong radius
        // Đơn giản hóa: lấy tất cả chuyến FINDING_DRIVER
        return tripRepository.findByStatus(TripStatus.FINDING_DRIVER);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @Cacheable(value = "tripsByPassenger", key = "#passengerId + ':' + (#status != null ? #status.name() : 'ALL') + ':' + #page + ':' + #limit")
    public Page<Trip> getPassengerHistory(UUID passengerId, TripStatus status, int page, int limit) {
        Pageable pageable = PageRequest.of(page - 1, limit, Sort.by("createdAt").descending());
        
        if (status != null) {
            return tripRepository.findByPassengerIdAndStatus(passengerId, status, pageable);
        }
        return tripRepository.findByPassengerId(passengerId, pageable);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @Cacheable(value = "tripsByDriver", key = "#driverId + ':' + (#status != null ? #status.name() : 'ALL') + ':' + #page + ':' + #limit")
    public Page<Trip> getDriverHistory(UUID driverId, TripStatus status, int page, int limit) {
        Pageable pageable = PageRequest.of(page - 1, limit, Sort.by("createdAt").descending());
        
        if (status != null) {
            return tripRepository.findByDriverIdAndStatus(driverId, status, pageable);
        }
        return tripRepository.findByDriverId(driverId, pageable);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @Cacheable(value = "driverEarnings", key = "#driverId + ':' + #period + ':' + (#from != null ? #from.toEpochSecond() : 'NF') + ':' + (#to != null ? #to.toEpochSecond() : 'NT')")
    public EarningsData calculateEarnings(UUID driverId, String period, OffsetDateTime from, OffsetDateTime to) {
        // Xác định khoảng thời gian
        if (from == null || to == null) {
            OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
            String effective = (period != null ? period : "today");
            switch (effective) {
                case "today" -> { from = now.truncatedTo(ChronoUnit.DAYS); to = now; }
                case "week" -> { from = now.minusWeeks(1); to = now; }
                case "month" -> { from = now.minusMonths(1); to = now; }
                case "year" -> { from = now.minusYears(1); to = now; }
                default -> { from = now.truncatedTo(ChronoUnit.DAYS); to = now; }
            }
        }
        
        List<Trip> allTrips = tripRepository.findByDriverIdAndCreatedAtBetween(driverId, from, to);
        List<Trip> completedTrips = allTrips.stream()
                .filter(t -> t.getStatus() == TripStatus.COMPLETED)
                .toList();
        List<Trip> cancelledTrips = allTrips.stream()
                .filter(t -> t.getStatus() == TripStatus.CANCELLED)
                .toList();
        
        double totalEarnings = completedTrips.stream()
                .mapToDouble(t -> {
                    Double p = t.getPrice();
                    return p == null ? 0.0 : p;
                })
            .sum();
        
        double averageEarnings = completedTrips.isEmpty() ? 0.0 : totalEarnings / completedTrips.size();
        
        // Tính phí hoa hồng (giả sử 15%)
        double commission = totalEarnings * -0.15;
        double netEarnings = totalEarnings + commission;
        
        return new EarningsData(
                allTrips.size(),
                completedTrips.size(),
                cancelledTrips.size(),
                totalEarnings,
                averageEarnings,
                totalEarnings,
                0.0,  // bonuses
                0.0,  // tips
                commission,
                netEarnings,
                from,
                to
        );
    }

    public static class EarningsData {
        public int totalTrips;
        public int completedTrips;
        public int cancelledTrips;
        public double totalEarnings;
        public double averageEarningsPerTrip;
        public double tripFees;
        public double bonuses;
        public double tips;
        public double commission;
        public double netEarnings;
        public OffsetDateTime from;
        public OffsetDateTime to;

        public EarningsData(int totalTrips, int completedTrips, int cancelledTrips,
                          double totalEarnings, double averageEarningsPerTrip,
                          double tripFees, double bonuses, double tips,
                          double commission, double netEarnings,
                          OffsetDateTime from, OffsetDateTime to) {
            this.totalTrips = totalTrips;
            this.completedTrips = completedTrips;
            this.cancelledTrips = cancelledTrips;
            this.totalEarnings = totalEarnings;
            this.averageEarningsPerTrip = averageEarningsPerTrip;
            this.tripFees = tripFees;
            this.bonuses = bonuses;
            this.tips = tips;
            this.commission = commission;
            this.netEarnings = netEarnings;
            this.from = from;
            this.to = to;
        }
    }
}
