# User Service API Specification

**Service Name**: `user-service`
**Technology**: Java (Spring Boot)
**Default Port**: `8080`
**Responsibility**: Quản lý thông tin người dùng (hành khách và tài xế), xử lý đăng ký, đăng nhập và hồ sơ.

---

## 1. Authentication & Authorization

### `POST /sessions` (Đăng nhập)

- **Mô tả:** Xác thực người dùng và trả về token.
- **Request Body:**
  ```json
  {
    "email": "example@uit.edu.vn",
    "password": "mysecretpassword"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "access_token": "your-json-web-token-here"
  }
  ```

## 2. User Management

### `POST /users` (Đăng ký)

- **Mô tả:** Đăng ký tài khoản (Hành khách US1). Hỗ trợ đăng ký cho Tài xế (Tài xế US1).
- **Request Body:**
  ```json
  {
    "email": "example@uit.edu.vn",
    "password": "mysecretpassword",
    "fullName": "Nguyen Van A",
    "phone": "0909123456",
    "role": "PASSENGER", // hoặc "DRIVER"

    "vehicleInfo": {
      // [MỚI] Chỉ yêu cầu khi role="DRIVER"
      "plate_number": "51G-123.45",
      "model": "Toyota Vios",
      "type": "4_SEATS"
    }
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "id": "user-uuid-123",
    "email": "example@uit.edu.vn",
    "fullName": "Nguyen Van A",
    "role": "PASSENGER",
    "createdAt": "2025-10-25T10:00:00Z"
  }
  ```

### `GET /users/me` (Lấy hồ sơ)

- **Mô tả:** Lấy thông tin hồ sơ của người dùng đã xác thực (dùng token).
- **Header:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):**
  ```json
  {
    "id": "user-uuid-123",
    "email": "example@uit.edu.vn",
    "fullName": "Nguyen Van A",
    "phone": "0909123456",
    "role": "PASSENGER"
  }
  ```
