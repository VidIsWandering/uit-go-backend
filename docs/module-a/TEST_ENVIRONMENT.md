# Môi trường Kiểm thử (Test Environment)

Để đảm bảo tính khách quan và khả năng tái lập (reproducibility) của kết quả kiểm thử hiệu năng, tài liệu này ghi lại chi tiết cấu hình phần cứng và phần mềm của môi trường kiểm thử (Local Environment).

## 1. Cấu hình Phần cứng (Host Machine)

- **Model**: Laptop cá nhân
- **CPU**: 13th Gen Intel(R) Core(TM) i7-1355U
- **RAM (Tổng)**: 32 GB
- **Hệ điều hành**: Windows 11 (chạy WSL2 - Ubuntu Kernel 5.15+)

## 2. Cấu hình Ảo hóa (WSL2 & Docker)

Hệ thống chạy trên nền tảng Docker Desktop for Windows, sử dụng backend WSL2 (Windows Subsystem for Linux).

- **RAM khả dụng cho Test (WSL2)**: ~16 GB (Theo kết quả lệnh `free -h` thực tế).
- **vCPU cấp cho WSL2**: Mặc định (Sử dụng toàn bộ các nhân khả dụng của Host CPU).
- **Swap**: 4 GB (Mặc định).

> **Lưu ý**: Môi trường WSL2 đang chạy ở chế độ cấu hình mặc định (Default Configuration). RAM được cấp phát động khoảng 50% tổng RAM của máy Host (32GB). Các container Docker sẽ chia sẻ tài nguyên trong giới hạn này.

## 3. Cấu hình Docker Compose (Resource Limits)

Hiện tại, các container được cấu hình ở chế độ **Unbounded** (không giới hạn cứng CPU/RAM từng container), cho phép chúng tận dụng tối đa tài nguyên rảnh của WSL2.

- **User Service**: Java Heap Max (Mặc định ~25% RAM hệ thống nếu không set Xmx)
- **Trip Service**: Java Heap Max (Mặc định)
- **Driver Service**: Node.js Default
- **PostgreSQL**: Shared Buffers (Default)

## 4. Công cụ Kiểm thử

- **Load Generator**: k6 (v0.47.0) chạy trong Docker container.
- **Monitoring**:
  - Prometheus (thu thập metrics mỗi 15s).
  - InfluxDB (lưu trữ metrics từ k6).
  - Grafana (hiển thị Dashboard).
