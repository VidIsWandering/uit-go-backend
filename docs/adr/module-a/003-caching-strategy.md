# ADR 003: Chiến lược Caching & Geo-spatial Optimization

## Bối cảnh

1.  **High Frequency Access**: Thông tin User, Config được truy xuất trong mỗi request.
2.  **High IOPS Write**: Tài xế cập nhật vị trí liên tục (ví dụ: 5 giây/lần). Việc ghi trực tiếp vào Database (Disk I/O) sẽ làm sập DB nhanh chóng ở quy mô lớn.
3.  **Complex Query**: Truy vấn "Tìm tài xế trong bán kính 2km" là phép toán tốn kém nếu thực hiện trên DB quan hệ.

## Quyết định

Sử dụng **Redis (AWS ElastiCache)** làm lớp đệm hiệu năng cao và xử lý dữ liệu không gian.

### 1. Caching Strategy (User/Config)

- **Pattern**: Cache-Aside (Lazy Loading).
- **Invalidation**: Sử dụng TTL (Time-to-Live) ngắn cho dữ liệu hay thay đổi và TTL dài cho dữ liệu tĩnh. Kết hợp xóa cache chủ động khi có update.
- **Prevention**:
  - **Cache Penetration**: Lưu giá trị NULL cho các key không tồn tại.
  - **Cache Stampede**: Sử dụng Locking hoặc Jitter (randomize TTL) để tránh hàng loạt key hết hạn cùng lúc.

### 2. Geo-spatial Optimization (Driver Location)

- **Giải pháp**: Sử dụng **Redis Geospatial** (`GEOADD`, `GEORADIUS`).
- **Lý do**:
  - **In-Memory Speed**: Redis xử lý hàng trăm nghìn thao tác ghi/giây (Write Ops) trên RAM, vượt trội so với PostGIS (Disk-based).
  - **Real-time**: Phù hợp hoàn hảo cho bài toán tracking vị trí thời gian thực.
- **Persistence**: Dữ liệu vị trí trong Redis là phù du (Ephemeral). Chúng ta sẽ có một Worker định kỳ (hoặc khi kết thúc chuyến) để đồng bộ lịch sử di chuyển xuống Database để lưu trữ lâu dài (Cold Storage).

## Hệ quả

### Tích cực

- **Extreme Performance**: Giảm độ trễ API xuống mức mili-giây.
- **Database Protection**: Chắn (Shield) phần lớn traffic không cho xuống DB, bảo vệ DB khỏi quá tải.

### Tiêu cực

- **Data Consistency**: Rủi ro mất dữ liệu vị trí mới nhất nếu Redis sập (chấp nhận được vì vị trí sẽ được cập nhật lại sau 5s).
- **Cost**: RAM đắt hơn Disk. Cần tính toán dung lượng Redis hợp lý.

## Trạng thái

Accepted
