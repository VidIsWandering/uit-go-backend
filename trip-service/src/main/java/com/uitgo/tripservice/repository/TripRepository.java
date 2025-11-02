package com.uitgo.tripservice.repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.model.TripStatus;

public interface TripRepository extends JpaRepository<Trip, UUID> {
    List<Trip> findByStatus(TripStatus status);
    
    Page<Trip> findByPassengerId(UUID passengerId, Pageable pageable);
    
    Page<Trip> findByPassengerIdAndStatus(UUID passengerId, TripStatus status, Pageable pageable);
    
    Page<Trip> findByDriverId(UUID driverId, Pageable pageable);
    
    Page<Trip> findByDriverIdAndStatus(UUID driverId, TripStatus status, Pageable pageable);
    
    List<Trip> findByDriverIdAndCreatedAtBetween(UUID driverId, OffsetDateTime from, OffsetDateTime to);
}
