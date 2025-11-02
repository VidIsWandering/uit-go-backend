# Hợp đồng API (API Contracts) - UIT-Go (Full 10 User Stories)

Đây là hợp đồng giao tiếp (JSON qua RESTful API) giữa các microservices.
* `user-service` (Java): Chạy trên port `8080`
* `trip-service` (Java): Chạy trên port `8081`
* `driver-service` (Node.js): Chạy trên port `8082`

---

## 1. UserService (Role A - Java)
* **Port:** `8080`
* **Trách nhiệm:** Quản lý đăng ký, đăng nhập, hồ sơ người dùng.

### `POST /users` (Đăng ký) - [ĐIỀU CHỈNH]
* **Mô tả:** Đăng ký tài khoản (Hành khách US1). Hỗ trợ đăng ký cho Tài xế (Tài xế US1).
* **Request Body:**
    ```json
    {
      "email": "example@uit.edu.vn",
      "password": "mysecretpassword",
  "fullName": "Nguyen Van A",
      "phone": "0909123456",
      "role": "PASSENGER", // hoặc "DRIVER"
      
  "vehicleInfo": { // [MỚI] Chỉ yêu cầu khi role="DRIVER"
        "plate_number": "51G-123.45",
        "model": "Toyota Vios",
        "type": "4_SEATS"
      }
    }
    ```
* **Success Response (201 Created):**
    ```json
    {
      "id": "user-uuid-123",
      "email": "example@uit.edu.vn",
  "fullName": "Nguyen Van A",
      "role": "PASSENGER",
  "createdAt": "2025-10-25T10:00:00Z"
    }
    ```

### `POST /sessions` (Đăng nhập)
* **Mô tả:** Xác thực người dùng và trả về token.
* **Request Body:**
    ```json
    {
      "email": "example@uit.edu.vn",
      "password": "mysecretpassword"
    }
    ```
* **Success Response (200 OK):**
    ```json
    {
      "access_token": "your-json-web-token-here"
    }
    ```

### `GET /users/me` (Lấy hồ sơ)
* **Mô tả:** Lấy thông tin hồ sơ của người dùng đã xác thực (dùng token).
* **Header:** `Authorization: Bearer <access_token>`
* **Success Response (200 OK):**
    ```json
    {
      "id": "user-uuid-123",
      "email": "example@uit.edu.vn",
  "fullName": "Nguyen Van A",
      "phone": "0909123456",
      "role": "PASSENGER"
    }
    ```

---

## 2. DriverService (Role B - Node.js)
* **Port:** `8082`
* **Trách nhiệm:** Quản lý trạng thái và vị trí tài xế.

### `PUT /drivers/:id/location` (Cập nhật vị trí)
* **Mô tả:** Tài xế cập nhật vị trí theo thời gian thực (Tài xế US4).
* **Params:** `:id` là ID của tài xế.
* **Request Body:**
    ```json
    {
      "latitude": 10.8700,
      "longitude": 106.8030
    }
    ```
* **Success Response (200 OK):**
    ```json
    {
      "status": "updated",
  "driverId": "driver-uuid-456"
    }
    ```

### `GET /drivers/search` (Tìm tài xế)
* **Mô tả:** Tìm tài xế `ONLINE` gần nhất (Hỗ trợ TripService).
* **Query Params:**
    * `lat`: vĩ độ của khách
    * `lng`: kinh độ của khách
* **Success Response (200 OK):**
    ```json
    {
      "drivers": [
        {
          "driverId": "driver-uuid-456",
          "distanceKm": 0.15
        }
      ]
    }
    ```

### `PUT /drivers/:id/status` (Cập nhật trạng thái) - [MỚI]
* **Mô tả:** Tài xế bật/tắt trạng thái "Sẵn sàng" (Tài xế US2).
* **Params:** `:id` là ID của tài xế.
* **Request Body:**
    ```json
    {
      "status": "ONLINE" // hoặc "OFFLINE"
    }
    ```
* **Success Response (200 OK):**
    ```json
    {
  "driverId": "driver-uuid-456",
      "status": "ONLINE"
    }
    ```

### `GET /drivers/:id/location` (Lấy vị trí 1 tài xế) - [MỚI]
* **Mô tả:** API nội bộ để `TripService` gọi (Hỗ trợ Hành khách US3).
* **Params:** `:id` là ID của tài xế.
* **Success Response (200 OK):**
    ```json
    {
      "driver_id": "driver-uuid-456",
      "location": {
        "latitude": 10.8701,
        "longitude": 106.8031
      }
    }
    ```

---

## 3. TripService (Role A - Java)
* **Port:** `8081`
* **Trách nhiệm:** Dịch vụ trung tâm, xử lý logic và trạng thái chuyến đi.

### `POST /trips` (Tạo chuyến đi)
* **Mô tả:** Hành khách yêu cầu một chuyến đi.
* **Header:** `Authorization: Bearer <access_token>` (của hành khách)
* **Luồng nội bộ:** Service này sẽ gọi `GET /drivers/search` (của `DriverService`).
* **Request Body:**
    ```json
    {
      "origin": { "latitude": 10.8700, "longitude": 106.8030 },
      "destination": { "latitude": 10.8800, "longitude": 106.8130 }
    }
    ```
* **Success Response (201 Created):**
    ```json
    {
      "id": "trip-uuid-abc",
  "passengerId": "user-uuid-123",
      "status": "FINDING_DRIVER",
  "createdAt": "2025-10-25T10:30:00Z"
    }
    ```

### `POST /trips/estimate` (Ước tính giá) - [MỚI]
* **Mô tả:** Hành khách xem giá cước ước tính (Hành khách US2).
* **Request Body:**
    ```json
    {
      "origin": { "latitude": 10.8700, "longitude": 106.8030 },
      "destination": { "latitude": 10.8800, "longitude": 106.8130 }
    }
    ```
* **Success Response (200 OK):**
    ```json
    {
  "estimatedPrice": 50000,
  "distanceMeters": 2500
    }
    ```

### `POST /trips/:id/accept` (Tài xế chấp nhận) - [MỚI]
* **Mô tả:** Tài xế chấp nhận chuyến đi (Tài xế US3).
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Params:** `:id` là ID chuyến đi.
* **Success Response (200 OK):**
    ```json
    {
      "id": "trip-uuid-abc",
      "status": "DRIVER_ACCEPTED",
      ...
    }
    ```

### `POST /trips/:id/reject` (Tài xế từ chối) - [MỚI]
* **Mô tả:** Tài xế từ chối chuyến đi (Tài xế US3).
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Params:** `:id` là ID chuyến đi.
* **Success Response (200 OK):**
    ```json
    {
      "id": "trip-uuid-abc",
      "status": "FINDING_DRIVER" // Trở lại trạng thái tìm tài xế khác
    }
    ```

### `POST /trips/:id/complete` (Hoàn thành chuyến) - [MỚI]
* **Mô tả:** Tài xế hoàn thành chuyến (Tài xế US5).
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Params:** `:id` là ID chuyến đi.
* **Success Response (200 OK):**
    ```json
    {
      "id": "trip-uuid-abc",
      "status": "COMPLETED"
    }
    ```

### `POST /trips/:id/cancel` (Hủy chuyến)
* **Mô tả:** Hành khách hủy chuyến đi (Hành khách US4).
* **Header:** `Authorization: Bearer <token_hanh_khach>`
* **Params:** `:id` là ID của chuyến đi.
* **Success Response (200 OK):**
    ```json
    {
      "id": "trip-uuid-abc",
      "status": "CANCELLED",
      "message": "Trip has been cancelled by passenger."
    }
    ```

### `POST /trips/:id/rating` (Đánh giá) - [MỚI]
* **Mô tả:** Hành khách đánh giá chuyến đi (Hành khách US5).
* **Header:** `Authorization: Bearer <token_hanh_khach>`
* **Params:** `:id` là ID chuyến đi.
* **Request Body:**
    ```json
    {
      "rating": 5,
      "comment": "Tài xế tuyệt vời!"
    }
    ```
* **Success Response (201 Created):**
    ```json
    {
  "tripId": "trip-uuid-abc",
      "rating": 5,
      "comment": "Tài xế tuyệt vời!"
    }
    ```
        
### `GET /trips/:id/driver-location` (Theo dõi vị trí) - [MỚI]
* **Mô tả:** API để app hành khách gọi (polling) mỗi 5s (Hành khách US3).
* **Header:** `Authorization: Bearer <token_hanh_khach>`
* **Luồng nội bộ:** Service này sẽ gọi `GET /drivers/:id/location` của `DriverService`.
* **Success Response (200 OK):**
    ```json
    {
      "driver_id": "driver-uuid-456",
      "location": {
        "latitude": 10.8701,
        "longitude": 106.8031
      }
    }
    ```

### `GET /trips/:id` (Lấy chi tiết chuyến đi) - [BỔ SUNG]
* **Mô tả:** Lấy thông tin chi tiết của một chuyến đi cụ thể.
* **Header:** `Authorization: Bearer <access_token>` (Hành khách hoặc Tài xế)
* **Params:** `:id` là ID của chuyến đi.
* **Success Response (200 OK):**
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
      "origin": { "latitude": 10.8700, "longitude": 106.8030 },
      "destination": { "latitude": 10.8800, "longitude": 106.8130 },
      "estimatedPrice": 50000,
      "actualPrice": 48000,
      "status": "IN_PROGRESS",
      "createdAt": "2025-10-25T10:30:00Z",
      "acceptedAt": "2025-10-25T10:31:00Z",
      "startedAt": "2025-10-25T10:35:00Z",
      "completedAt": null
    }
    ```

### `POST /trips/:id/start` (Bắt đầu chuyến đi) - [BỔ SUNG]
* **Mô tả:** Tài xế bấm "Bắt đầu" sau khi đón khách xong (chuyển từ DRIVER_ACCEPTED → IN_PROGRESS).
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Params:** `:id` là ID chuyến đi.
* **Success Response (200 OK):**
    ```json
    {
      "id": "trip-uuid-abc",
      "status": "IN_PROGRESS",
      "startedAt": "2025-10-25T10:35:00Z"
    }
    ```

### `GET /trips/available` (Lấy danh sách chuyến đi khả dụng) - [BỔ SUNG]
* **Mô tả:** Tài xế xem các chuyến đi đang chờ gần vị trí hiện tại (Tài xế US3).
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Query Params:**
    * `radius`: Bán kính tìm kiếm (meters), mặc định 5000
* **Success Response (200 OK):**
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
          "origin": { "latitude": 10.8700, "longitude": 106.8030 },
          "destination": { "latitude": 10.8800, "longitude": 106.8130 },
          "estimatedPrice": 50000,
          "distanceFromDriver": 150,
          "createdAt": "2025-10-25T10:30:00Z"
        }
      ]
    }
    ```

### `GET /trips/passenger/:passengerId/history` (Lịch sử chuyến đi - Hành khách) - [BỔ SUNG]
* **Mô tả:** Lấy danh sách lịch sử chuyến đi của hành khách (hỗ trợ Hành khách US5).
* **Header:** `Authorization: Bearer <token_hanh_khach>`
* **Params:** `:passengerId` là ID của hành khách.
* **Query Params:**
    * `status`: Filter theo trạng thái (COMPLETED, CANCELLED), optional
    * `page`: Số trang (mặc định 1)
    * `limit`: Số bản ghi mỗi trang (mặc định 20)
* **Success Response (200 OK):**
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
          "origin": { "latitude": 10.8700, "longitude": 106.8030 },
          "destination": { "latitude": 10.8800, "longitude": 106.8130 },
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

### `GET /trips/driver/:driverId/history` (Lịch sử chuyến đi - Tài xế) - [BỔ SUNG]
* **Mô tả:** Lấy danh sách lịch sử chuyến đi của tài xế (hỗ trợ Tài xế US5).
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Params:** `:driverId` là ID của tài xế.
* **Query Params:**
    * `status`: Filter theo trạng thái, optional
    * `page`: Số trang (mặc định 1)
    * `limit`: Số bản ghi mỗi trang (mặc định 20)
* **Success Response (200 OK):**
    ```json
    {
      "trips": [
        {
          "id": "trip-uuid-abc",
          "passengerId": "user-uuid-123",
          "passengerInfo": {
            "fullName": "Nguyen Van A"
          },
          "origin": { "latitude": 10.8700, "longitude": 106.8030 },
          "destination": { "latitude": 10.8800, "longitude": 106.8130 },
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

### `GET /trips/driver/:driverId/earnings` (Doanh thu của tài xế) - [BỔ SUNG]
* **Mô tả:** Lấy thông tin doanh thu của tài xế (hỗ trợ Tài xế US5 - "ghi nhận doanh thu").
* **Header:** `Authorization: Bearer <token_tai_xe>`
* **Params:** `:driverId` là ID của tài xế.
* **Query Params:**
    * `period`: Khoảng thời gian (today, week, month, year), mặc định "today"
    * `from`: Ngày bắt đầu (ISO 8601), optional
    * `to`: Ngày kết thúc (ISO 8601), optional
* **Success Response (200 OK):**
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