package com.uitgo.tripservice.service;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import javax.transaction.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
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

    public Optional<Trip> getTripById(UUID tripId) {
        return tripRepository.findById(tripId);
    }

    @Transactional
    public Trip acceptTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (trip.getStatus() != TripStatus.FINDING_DRIVER) {
            throw new RuntimeException("Trip is not available for acceptance");
        }
        
        trip.setDriverId(driverId);
        trip.setStatus(TripStatus.DRIVER_ACCEPTED);
        trip.setAcceptedAt(OffsetDateTime.now(ZoneOffset.UTC));
        return tripRepository.save(trip);
    }

    @Transactional
    public void rejectTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (trip.getStatus() != TripStatus.FINDING_DRIVER) {
            throw new RuntimeException("Trip is not available for rejection");
        }
        
        // Logic: Trong thực tế, có thể cần tìm tài xế khác
        // Ở đây chúng ta chỉ giữ nguyên trạng thái FINDING_DRIVER
    }

    @Transactional
    public Trip startTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(tripId)
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
    public Trip completeTrip(UUID tripId, UUID driverId) {
        Trip trip = tripRepository.findById(tripId)
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
    public Trip cancelTrip(UUID tripId, UUID passengerId) {
        Trip trip = tripRepository.findById(tripId)
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
    public Trip rateTrip(UUID tripId, UUID passengerId, int rating, String comment) {
        Trip trip = tripRepository.findById(tripId)
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

    public List<Trip> getAvailableTrips(Location driverLocation, int radiusMeters) {
        // Lấy các chuyến đi đang chờ tài xế
        // Trong thực tế, nên dùng spatial query để tìm trong radius
        // Đơn giản hóa: lấy tất cả chuyến FINDING_DRIVER
        return tripRepository.findByStatus(TripStatus.FINDING_DRIVER);
    }

    public Page<Trip> getPassengerHistory(UUID passengerId, TripStatus status, int page, int limit) {
        Pageable pageable = PageRequest.of(page - 1, limit, Sort.by("createdAt").descending());
        
        if (status != null) {
            return tripRepository.findByPassengerIdAndStatus(passengerId, status, pageable);
        }
        return tripRepository.findByPassengerId(passengerId, pageable);
    }

    public Page<Trip> getDriverHistory(UUID driverId, TripStatus status, int page, int limit) {
        Pageable pageable = PageRequest.of(page - 1, limit, Sort.by("createdAt").descending());
        
        if (status != null) {
            return tripRepository.findByDriverIdAndStatus(driverId, status, pageable);
        }
        return tripRepository.findByDriverId(driverId, pageable);
    }

    public EarningsData calculateEarnings(UUID driverId, String period, OffsetDateTime from, OffsetDateTime to) {
        // Xác định khoảng thời gian
        if (from == null || to == null) {
            OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
            switch (period != null ? period : "today") {
                case "today":
                    from = now.truncatedTo(ChronoUnit.DAYS);
                    to = now;
                    break;
                case "week":
                    from = now.minusWeeks(1);
                    to = now;
                    break;
                case "month":
                    from = now.minusMonths(1);
                    to = now;
                    break;
                case "year":
                    from = now.minusYears(1);
                    to = now;
                    break;
                default:
                    from = now.truncatedTo(ChronoUnit.DAYS);
                    to = now;
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
                .mapToDouble(t -> t.getPrice() != null ? t.getPrice() : 0.0)
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
