package com.uitgo.tripservice.exception;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

import javax.persistence.OptimisticLockException;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({OptimisticLockException.class, ObjectOptimisticLockingFailureException.class})
    public ResponseEntity<Map<String, Object>> handleOptimisticLockException(Exception ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", OffsetDateTime.now());
        body.put("status", HttpStatus.CONFLICT.value());
        body.put("error", "Conflict");
        body.put("message", "Chuyến đi đã được cập nhật bởi người khác. Vui lòng thử lại.");
        body.put("details", "Optimistic locking failure - the trip has been modified by another transaction");
        
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body);
    }

    @ExceptionHandler(TripConcurrentUpdateException.class)
    public ResponseEntity<Map<String, Object>> handleTripConcurrentUpdateException(TripConcurrentUpdateException ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", OffsetDateTime.now());
        body.put("status", HttpStatus.CONFLICT.value());
        body.put("error", "Conflict");
        body.put("message", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", OffsetDateTime.now());
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Bad Request");
        body.put("message", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }
}
