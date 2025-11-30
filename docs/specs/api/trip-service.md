# Trip Service API Specification

**Service Name**: `trip-service`
**Technology**: Java (Spring Boot)
**Default Port**: `8081`
**Responsibility**: Dịch vụ trung tâm, xử lý logic tạo chuyến đi, quản lý các trạng thái của chuyến (đang tìm tài xế, đã chấp nhận, đang diễn ra, hoàn thành, đã hủy).

---

## 1. Booking Flow (Passenger)

### `POST /trips/estimate` (Ước tính giá)

- **Mô tả:** Hành khách xem giá cước ước tính (Hành khách US2).
- **Request Body:**
  ```json
  {
    "origin": { "latitude": 10.87, "longitude": 106.803 },
    "destination": { "latitude": 10.88, "longitude": 106.813 }
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "estimatedPrice": 50000,
    "distanceMeters": 2500
  }
  ```

### `POST /trips` (Tạo chuyến đi)

- **Mô tả:** Hành khách yêu cầu một chuyến đi.
- **Header:** `Authorization: Bearer <access_token>` (của hành khách)
- **Luồng nội bộ:** Service này sẽ gọi `GET /drivers/search` (của `DriverService`).
- **Request Body:**
  ```json
  {
    "origin": { "latitude": 10.87, "longitude": 106.803 },
    "destination": { "latitude": 10.88, "longitude": 106.813 }
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "id": "trip-uuid-abc",
    "passengerId": "user-uuid-123",
    "status": "FINDING_DRIVER",
    "createdAt": "2025-10-25T10:30:00Z"
  }
  ```

### `POST /trips/:id/cancel` (Hủy chuyến)

- **Mô tả:** Hành khách hủy chuyến đi (Hành khách US4).
- **Header:** `Authorization: Bearer <token_hanh_khach>`
- **Params:** `:id` là ID của chuyến đi.
- **Success Response (200 OK):**
  ```json
  {
    "id": "trip-uuid-abc",
    "status": "CANCELLED",
    "message": "Trip has been cancelled by passenger."
  }
  ```

### `GET /trips/:id/driver-location` (Theo dõi vị trí)

- **Mô tả:** API để app hành khách gọi (polling) mỗi 5s (Hành khách US3).
- **Header:** `Authorization: Bearer <token_hanh_khach>`
- **Luồng nội bộ:** Service này sẽ gọi `GET /drivers/:id/location` của `DriverService`.
- **Success Response (200 OK):**
  ```json
  {
    "driver_id": "driver-uuid-456",
    "location": {
      "latitude": 10.8701,
      "longitude": 106.8031
    }
  }
  ```

## 2. Driver Operations

### `GET /trips/available` (Lấy danh sách chuyến đi khả dụng)

- **Mô tả:** Tài xế xem các chuyến đi đang chờ gần vị trí hiện tại (Tài xế US3).
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Query Params:**
  - `radius`: Bán kính tìm kiếm (meters), mặc định 5000
- **Success Response (200 OK):**
  ```json
  {
    "trips": [
      {
        "id": "trip-uuid-abc",
        "passengerId": "user-uuid-123",
        "passengerInfo": {
          "fullName": "Nguyen Van A",
          "phone": "0909123456"
        },
        "origin": { "latitude": 10.87, "longitude": 106.803 },
        "destination": { "latitude": 10.88, "longitude": 106.813 },
        "estimatedPrice": 50000,
        "distanceFromDriver": 150,
        "createdAt": "2025-10-25T10:30:00Z"
      }
    ]
  }
  ```

### `POST /trips/:id/accept` (Tài xế chấp nhận)

- **Mô tả:** Tài xế chấp nhận chuyến đi (Tài xế US3).
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Params:** `:id` là ID chuyến đi.
- **Success Response (200 OK):**
  ```json
  {
    "id": "trip-uuid-abc",
    "status": "DRIVER_ACCEPTED",
    ...
  }
  ```

### `POST /trips/:id/reject` (Tài xế từ chối)

- **Mô tả:** Tài xế từ chối chuyến đi (Tài xế US3).
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Params:** `:id` là ID chuyến đi.
- **Success Response (200 OK):**
  ```json
  {
    "id": "trip-uuid-abc",
    "status": "FINDING_DRIVER" // Trở lại trạng thái tìm tài xế khác
  }
  ```

### `POST /trips/:id/start` (Bắt đầu chuyến đi)

- **Mô tả:** Tài xế bấm "Bắt đầu" sau khi đón khách xong (chuyển từ DRIVER_ACCEPTED → IN_PROGRESS).
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Params:** `:id` là ID chuyến đi.
- **Success Response (200 OK):**
  ```json
  {
    "id": "trip-uuid-abc",
    "status": "IN_PROGRESS",
    "startedAt": "2025-10-25T10:35:00Z"
  }
  ```

### `POST /trips/:id/complete` (Hoàn thành chuyến)

- **Mô tả:** Tài xế hoàn thành chuyến (Tài xế US5).
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Params:** `:id` là ID chuyến đi.
- **Success Response (200 OK):**
  ```json
  {
    "id": "trip-uuid-abc",
    "status": "COMPLETED"
  }
  ```

## 3. Trip Details & History

### `GET /trips/:id` (Lấy chi tiết chuyến đi)

- **Mô tả:** Lấy thông tin chi tiết của một chuyến đi cụ thể.
- **Header:** `Authorization: Bearer <access_token>` (Hành khách hoặc Tài xế)
- **Params:** `:id` là ID của chuyến đi.
- **Success Response (200 OK):**
  ```json
  {
    "id": "trip-uuid-abc",
    "passengerId": "user-uuid-123",
    "driverId": "driver-uuid-456",
    "passengerInfo": {
      "fullName": "Nguyen Van A",
      "phone": "0909123456"
    },
    "driverInfo": {
      "fullName": "Tran Van B",
      "phone": "0908765432",
      "vehicleInfo": {
        "plate_number": "51G-123.45",
        "model": "Toyota Vios",
        "type": "4_SEATS"
      }
    },
    "origin": { "latitude": 10.87, "longitude": 106.803 },
    "destination": { "latitude": 10.88, "longitude": 106.813 },
    "estimatedPrice": 50000,
    "actualPrice": 48000,
    "status": "IN_PROGRESS",
    "createdAt": "2025-10-25T10:30:00Z",
    "acceptedAt": "2025-10-25T10:31:00Z",
    "startedAt": "2025-10-25T10:35:00Z",
    "completedAt": null
  }
  ```

### `GET /trips/passenger/:passengerId/history` (Lịch sử chuyến đi - Hành khách)

- **Mô tả:** Lấy danh sách lịch sử chuyến đi của hành khách (hỗ trợ Hành khách US5).
- **Header:** `Authorization: Bearer <token_hanh_khach>`
- **Params:** `:passengerId` là ID của hành khách.
- **Query Params:**
  - `status`: Filter theo trạng thái (COMPLETED, CANCELLED), optional
  - `page`: Số trang (mặc định 1)
  - `limit`: Số bản ghi mỗi trang (mặc định 20)
- **Success Response (200 OK):**
  ```json
  {
    "trips": [
      {
        "id": "trip-uuid-abc",
        "driverId": "driver-uuid-456",
        "driverInfo": {
          "fullName": "Tran Van B",
          "vehicleInfo": {
            "plate_number": "51G-123.45",
            "model": "Toyota Vios"
          }
        },
        "origin": { "latitude": 10.87, "longitude": 106.803 },
        "destination": { "latitude": 10.88, "longitude": 106.813 },
        "actualPrice": 48000,
        "status": "COMPLETED",
        "completedAt": "2025-10-25T11:00:00Z",
        "rating": 5,
        "comment": "Tài xế tuyệt vời!"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalTrips": 87
    }
  }
  ```

### `GET /trips/driver/:driverId/history` (Lịch sử chuyến đi - Tài xế)

- **Mô tả:** Lấy danh sách lịch sử chuyến đi của tài xế (hỗ trợ Tài xế US5).
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Params:** `:driverId` là ID của tài xế.
- **Query Params:**
  - `status`: Filter theo trạng thái, optional
  - `page`: Số trang (mặc định 1)
  - `limit`: Số bản ghi mỗi trang (mặc định 20)
- **Success Response (200 OK):**
  ```json
  {
    "trips": [
      {
        "id": "trip-uuid-abc",
        "passengerId": "user-uuid-123",
        "passengerInfo": {
          "fullName": "Nguyen Van A"
        },
        "origin": { "latitude": 10.87, "longitude": 106.803 },
        "destination": { "latitude": 10.88, "longitude": 106.813 },
        "actualPrice": 48000,
        "status": "COMPLETED",
        "completedAt": "2025-10-25T11:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 12,
      "totalTrips": 234
    }
  }
  ```

## 4. Rating & Earnings

### `POST /trips/:id/rating` (Đánh giá)

- **Mô tả:** Hành khách đánh giá chuyến đi (Hành khách US5).
- **Header:** `Authorization: Bearer <token_hanh_khach>`
- **Params:** `:id` là ID chuyến đi.
- **Request Body:**
  ```json
  {
    "rating": 5,
    "comment": "Tài xế tuyệt vời!"
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "tripId": "trip-uuid-abc",
    "rating": 5,
    "comment": "Tài xế tuyệt vời!"
  }
  ```

### `GET /trips/driver/:driverId/earnings` (Doanh thu của tài xế)

- **Mô tả:** Lấy thông tin doanh thu của tài xế (hỗ trợ Tài xế US5 - "ghi nhận doanh thu").
- **Header:** `Authorization: Bearer <token_tai_xe>`
- **Params:** `:driverId` là ID của tài xế.
- **Query Params:**
  - `period`: Khoảng thời gian (today, week, month, year), mặc định "today"
  - `from`: Ngày bắt đầu (ISO 8601), optional
  - `to`: Ngày kết thúc (ISO 8601), optional
- **Success Response (200 OK):**
  ```json
  {
    "driverId": "driver-uuid-456",
    "period": "today",
    "totalTrips": 8,
    "completedTrips": 7,
    "cancelledTrips": 1,
    "totalEarnings": 350000,
    "averageEarningsPerTrip": 50000,
    "breakdown": {
      "tripFees": 350000,
      "bonuses": 20000,
      "tips": 15000,
      "commission": -52500,
      "netEarnings": 332500
    },
    "from": "2025-10-25T00:00:00Z",
    "to": "2025-10-25T23:59:59Z"
  }
  ```
