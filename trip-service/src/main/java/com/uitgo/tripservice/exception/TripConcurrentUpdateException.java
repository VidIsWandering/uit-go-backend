package com.uitgo.tripservice.exception;

public class TripConcurrentUpdateException extends RuntimeException {
    public TripConcurrentUpdateException(String message) {
        super(message);
    }

    public TripConcurrentUpdateException(String message, Throwable cause) {
        super(message, cause);
    }
}
