# ADR 003: Chiến lược Caching Tập trung & Tối ưu hóa Geo-spatial

## Bối cảnh

Trong Giai đoạn 1, Redis đã được sử dụng để lưu trữ vị trí tài xế (Geo-spatial). Tuy nhiên, khi chuyển sang kiến trúc Hyper-scale (Giai đoạn 2), hệ thống đối mặt với các thách thức mới:

1.  **Read-Heavy User Profile**: Mọi request đều cần xác thực và lấy thông tin User. Truy vấn Database liên tục gây quá tải.
2.  **High IOPS Write**: Tài xế cập nhật vị trí liên tục.
3.  **Complex Query**: Tìm kiếm tài xế trong bán kính R.

## Quyết định

Mở rộng vai trò của **Redis (AWS ElastiCache)** từ một kho lưu trữ vị trí đơn thuần thành **Trung tâm Caching (Centralized Caching Layer)** của toàn bộ hệ thống.

### 1. Centralized Caching (Mới trong Giai đoạn 2)

- **Mục tiêu**: Giảm tải cho Database (Offload DB) và giảm độ trễ API.
- **Đối tượng Cache**:
  - **User Profile**: Thông tin ít thay đổi, truy xuất nhiều.
  - **System Config**: Cấu hình hệ thống.
- **Chiến lược**:
  - **Pattern**: Cache-Aside (Lazy Loading). Ứng dụng tìm trong Cache trước, nếu miss mới tìm DB và update Cache.
  - **Consistency**: Sử dụng cơ chế **Cache Eviction** (xóa cache) ngay khi có thao tác Update/Delete dữ liệu gốc để đảm bảo tính nhất quán.

### 2. Geo-spatial Optimization (Kế thừa từ Giai đoạn 1)

- **Giải pháp**: Tiếp tục sử dụng **Redis Geospatial** (`GEOADD`, `GEORADIUS`) nhưng tối ưu hóa cho quy mô lớn.
- **Lý do**:
  - **In-Memory Speed**: Redis xử lý hàng trăm nghìn thao tác ghi/giây (Write Ops) trên RAM, vượt trội so với PostGIS (Disk-based).
  - **Real-time**: Phù hợp hoàn hảo cho bài toán tracking vị trí thời gian thực.

## Hệ quả

### Tích cực

- **Extreme Performance**: Giảm độ trễ API xác thực User từ ~50ms (DB) xuống ~1ms (Redis).
- **Database Protection**: Chắn (Shield) tới 90% traffic đọc User, bảo vệ DB khỏi quá tải trong các đợt Flash Crowd.

### Tiêu cực

- **Complexity**: Phải xử lý vấn đề Cache Invalidation (đồng bộ dữ liệu giữa Cache và DB).
- **Cost**: Chi phí RAM cao hơn Disk. Cần tính toán dung lượng và Eviction Policy (LRU) hợp lý.

## Trạng thái

Accepted
