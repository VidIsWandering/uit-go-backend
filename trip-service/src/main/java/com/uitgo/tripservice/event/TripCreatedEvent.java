package com.uitgo.tripservice.event;

import com.uitgo.tripservice.model.Location;
import com.uitgo.tripservice.model.Trip;

/**
 * Event published after a trip is successfully created and persisted.
 * 
 * Used with @TransactionalEventListener to decouple SQS messaging
 * from database transaction, preventing blocking I/O in transaction scope.
 */
public class TripCreatedEvent {
    private final Trip trip;
    private final Location origin;
    private final Location destination;

    public TripCreatedEvent(Trip trip, Location origin, Location destination) {
        this.trip = trip;
        this.origin = origin;
        this.destination = destination;
    }

    public Trip getTrip() {
        return trip;
    }

    public Location getOrigin() {
        return origin;
    }

    public Location getDestination() {
        return destination;
    }
}
