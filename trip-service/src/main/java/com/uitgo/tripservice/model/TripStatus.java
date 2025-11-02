package com.uitgo.tripservice.model;

public enum TripStatus {
    FINDING_DRIVER,    // Đang tìm tài xế
    DRIVER_ACCEPTED,   // Tài xế đã chấp nhận, đang di chuyển đến điểm đón
    IN_PROGRESS,       // Đã đón khách, đang di chuyển đến đích
    COMPLETED,         // Hoàn thành
    CANCELLED          // Đã hủy
}
