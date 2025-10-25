# Hợp đồng API (API Contracts) - UIT-Go

Đây là hợp đồng giao tiếp (JSON qua RESTful API) giữa các microservices.
* `user-service` (Java): Chạy trên port `8080`
* `trip-service` (Java): Chạy trên port `8081`
* `driver-service` (Node.js): Chạy trên port `8082`

---

## 1. UserService (Role A - Java)
* **Port:** `8080`
* **Trách nhiệm:** Quản lý đăng ký, đăng nhập, hồ sơ người dùng.

### `POST /users` (Đăng ký)
* **Mô tả:** Đăng ký tài khoản mới cho cả hành khách và tài xế.
* **Request Body:**
    ```json
    {
      "email": "example@uit.edu.vn",
      "password": "mysecretpassword",
      "full_name": "Nguyen Van A",
      "phone": "0909123456",
      "role": "PASSENGER" // hoặc "DRIVER"
    }
    ```
* **Success Response (201 Created):**
    ```json
    {
      "id": "user-uuid-123",
      "email": "example@uit.edu.vn",
      "full_name": "Nguyen Van A",
      "role": "PASSENGER",
      "created_at": "2025-10-25T10:00:00Z"
    }
    ```

### `POST /sessions` (Đăng nhập)
* **Mô tả:** Xác thực người dùng và trả về token (ví dụ: JWT).
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
      "full_name": "Nguyen Van A",
      "phone": "0909123456",
      "role": "PASSENGER"
    }
    ```

---

## 2. DriverService (Role B - Node.js)
* **Port:** `8082`
* **Trách nhiệm:** Quản lý trạng thái và vị trí tài xế.

### `PUT /drivers/:id/location` (Cập nhật vị trí)
* **Mô tả:** Tài xế cập nhật vị trí theo thời gian thực.
* **Params:** `:id` là ID của tài xế (user ID).
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
      "driver_id": "driver-uuid-456"
    }
    ```

### `GET /drivers/search` (Tìm tài xế) - **[API NỘI BỘ]**
* **Mô tả:** Tìm tài xế gần nhất trong bán kính 5km (ví dụ). **`TripService` (Java) sẽ gọi API này.**
* **Query Params:**
    * `lat`: vĩ độ của khách
    * `lng`: kinh độ của khách
* **Success Response (200 OK):**
    ```json
    {
      "drivers": [
        {
          "driver_id": "driver-uuid-456",
          "location": {
            "latitude": 10.8701,
            "longitude": 106.8031
          },
          "distance_meters": 150
        },
        {
          "driver_id": "driver-uuid-789",
          "location": {
            "latitude": 10.8710,
            "longitude": 106.8040
          },
          "distance_meters": 350
        }
      ]
    }
    ```

---

## 3. TripService (Role A - Java)
* **Port:** `8081`
* **Trách nhiệm:** Xử lý logic tạo và quản lý chuyến đi.

### `POST /trips` (Tạo chuyến đi)
* **Mô tả:** Hành khách yêu cầu một chuyến đi.
* **Header:** `Authorization: Bearer <access_token>` (của hành khách)
* **Luồng nội bộ:** Service này sẽ gọi `GET /users/me` (để lấy ID khách) và sau đó gọi `GET /drivers/search` (để tìm tài xế).
* **Request Body:**
    ```json
    {
      "origin": {
        "latitude": 10.8700,
        "longitude": 106.8030
      },
      "destination": {
        "latitude": 10.8800,
        "longitude": 106.8130
      }
    }
    ```
* **Success Response (201 Created):**
    ```json
    {
      "id": "trip-uuid-abc",
      "passenger_id": "user-uuid-123",
      "status": "FINDING_DRIVER",
      "origin": { "latitude": 10.8700, "longitude": 106.8030 },
      "destination": { "latitude": 10.8800, "longitude": 106.8130 },
      "created_at": "2025-10-25T10:30:00Z"
    }
    ```

### `POST /trips/:id/cancel` (Hủy chuyến)
* **Mô tả:** Hành khách hủy chuyến đi.
* **Header:** `Authorization: Bearer <access_token>`
* **Params:** `:id` là ID của chuyến đi.
* **Success Response (200 OK):**
    ```json
    {
      "id": "trip-uuid-abc",
      "status": "CANCELLED",
      "message": "Trip has been cancelled by passenger."
    }
    ```