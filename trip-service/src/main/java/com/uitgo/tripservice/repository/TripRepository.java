package com.uitgo.tripservice.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.uitgo.tripservice.model.Trip;

public interface TripRepository extends JpaRepository<Trip, UUID> {
}
