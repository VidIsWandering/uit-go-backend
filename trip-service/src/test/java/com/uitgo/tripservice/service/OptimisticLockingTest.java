package com.uitgo.tripservice.service;

import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.uitgo.tripservice.exception.TripConcurrentUpdateException;
import com.uitgo.tripservice.model.Trip;
import com.uitgo.tripservice.model.TripStatus;
import com.uitgo.tripservice.repository.TripRepository;

/**
 * Test case để demo Optimistic Locking behavior
 * Mô phỏng scenario: 2 drivers cùng lúc accept 1 trip
 */
@SpringBootTest
@ActiveProfiles("test")
class OptimisticLockingTest {

    @Autowired
    private TripService tripService;

    @Autowired
    private TripRepository tripRepository;

    @Test
    void testConcurrentAcceptTrip_shouldPreventRaceCondition() throws InterruptedException {
        // Setup: Tạo 1 trip mới
        Trip trip = new Trip();
        trip.setPassengerId(UUID.randomUUID());
        trip.setStatus(TripStatus.FINDING_DRIVER);
        trip.setOriginLatitude(10.762622);
        trip.setOriginLongitude(106.660172);
        trip.setDestinationLatitude(10.768553);
        trip.setDestinationLongitude(106.676372);
        Trip savedTrip = tripRepository.save(trip);
        UUID tripId = savedTrip.getId();

        // 2 drivers
        UUID driver1 = UUID.randomUUID();
        UUID driver2 = UUID.randomUUID();

        // Counter để đếm số lần success/failure
        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger conflictCount = new AtomicInteger(0);

        // Sử dụng CountDownLatch để đảm bảo 2 threads chạy đồng thời
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch doneLatch = new CountDownLatch(2);

        ExecutorService executor = Executors.newFixedThreadPool(2);

        // Thread 1: Driver 1 accept trip
        executor.submit(() -> {
            try {
                startLatch.await(); // Đợi tín hiệu start
                tripService.acceptTrip(tripId, driver1);
                successCount.incrementAndGet();
                System.out.println("✅ Driver 1 accepted successfully");
            } catch (TripConcurrentUpdateException e) {
                conflictCount.incrementAndGet();
                System.out.println("❌ Driver 1 got conflict: " + e.getMessage());
            } catch (Exception e) {
                System.out.println("⚠️ Driver 1 error: " + e.getMessage());
            } finally {
                doneLatch.countDown();
            }
        });

        // Thread 2: Driver 2 accept trip
        executor.submit(() -> {
            try {
                startLatch.await(); // Đợi tín hiệu start
                tripService.acceptTrip(tripId, driver2);
                successCount.incrementAndGet();
                System.out.println("✅ Driver 2 accepted successfully");
            } catch (TripConcurrentUpdateException e) {
                conflictCount.incrementAndGet();
                System.out.println("❌ Driver 2 got conflict: " + e.getMessage());
            } catch (Exception e) {
                System.out.println("⚠️ Driver 2 error: " + e.getMessage());
            } finally {
                doneLatch.countDown();
            }
        });

        // Start đồng thời 2 threads
        startLatch.countDown();
        
        // Đợi cả 2 threads xong
        doneLatch.await();
        executor.shutdown();

        // Assertions
        assertEquals(1, successCount.get(), "Chỉ 1 driver được accept");
        assertEquals(1, conflictCount.get(), "1 driver bị conflict");

        // Kiểm tra DB
        Trip finalTrip = tripRepository.findById(tripId).orElseThrow();
        assertEquals(TripStatus.DRIVER_ACCEPTED, finalTrip.getStatus());
        assertNotNull(finalTrip.getDriverId(), "Trip phải có driver_id");
        assertNotNull(finalTrip.getVersion(), "Version phải được tăng");

        System.out.println("\n📊 Kết quả:");
        System.out.println("  - Success: " + successCount.get());
        System.out.println("  - Conflict: " + conflictCount.get());
        System.out.println("  - Final driver: " + finalTrip.getDriverId());
        System.out.println("  - Version: " + finalTrip.getVersion());
    }

    @Test
    void testSequentialAccept_shouldWork() {
        // Test case thông thường (không concurrent)
        Trip trip = new Trip();
        trip.setPassengerId(UUID.randomUUID());
        trip.setStatus(TripStatus.FINDING_DRIVER);
        trip.setOriginLatitude(10.762622);
        trip.setOriginLongitude(106.660172);
        trip.setDestinationLatitude(10.768553);
        trip.setDestinationLongitude(106.676372);
        Trip savedTrip = tripRepository.save(trip);

        UUID driverId = UUID.randomUUID();
        Trip acceptedTrip = tripService.acceptTrip(savedTrip.getId(), driverId);

        assertEquals(TripStatus.DRIVER_ACCEPTED, acceptedTrip.getStatus());
        assertEquals(driverId, acceptedTrip.getDriverId());
        assertNotNull(acceptedTrip.getVersion());
    }
}
