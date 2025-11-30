# Driver Service API Specification

**Service Name**: `driver-service`
**Technology**: Node.js (Express)
**Default Port**: `8082`
**Responsibility**: Quản lý trạng thái (Online/Offline) và vị trí của tài xế theo thời gian thực.

---

## 1. Driver Location Management

### `PUT /drivers/:id/location` (Cập nhật vị trí)

- **Mô tả:** Tài xế cập nhật vị trí theo thời gian thực (Tài xế US4).
- **Params:** `:id` là ID của tài xế.
- **Request Body:**
  ```json
  {
    "latitude": 10.87,
    "longitude": 106.803
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "status": "updated",
    "driverId": "driver-uuid-456"
  }
  ```

### `GET /drivers/:id/location` (Lấy vị trí 1 tài xế)

- **Mô tả:** API nội bộ để `TripService` gọi (Hỗ trợ Hành khách US3).
- **Params:** `:id` là ID của tài xế.
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

## 2. Driver Status & Search

### `PUT /drivers/:id/status` (Cập nhật trạng thái)

- **Mô tả:** Tài xế bật/tắt trạng thái "Sẵn sàng" (Tài xế US2).
- **Params:** `:id` là ID của tài xế.
- **Request Body:**
  ```json
  {
    "status": "ONLINE" // hoặc "OFFLINE"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "driverId": "driver-uuid-456",
    "status": "ONLINE"
  }
  ```

### `GET /drivers/search` (Tìm tài xế)

- **Mô tả:** Tìm tài xế `ONLINE` gần nhất (Hỗ trợ TripService).
- **Query Params:**
  - `lat`: vĩ độ của khách
  - `lng`: kinh độ của khách
- **Success Response (200 OK):**
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
