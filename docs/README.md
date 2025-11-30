# Tài liệu Dự án UIT-Go Backend

Chào mừng đến với kho lưu trữ tài liệu kỹ thuật của dự án **UIT-Go Backend**.
Thư mục này chứa toàn bộ thông tin về kiến trúc, quyết định thiết kế, kế hoạch triển khai và báo cáo kết quả.

## 📚 Mục lục Tài liệu

### 1. Tổng quan & Kiến trúc

- **[Báo cáo Tổng kết (Final Report)](./REPORT.md)**: Tài liệu tổng hợp quá trình thực hiện, kết quả đạt được và bài học kinh nghiệm.
- **[Kiến trúc Hệ thống (System Architecture)](./ARCHITECTURE.md)**: Mô tả chi tiết kiến trúc Cloud (AWS), sơ đồ luồng dữ liệu và các thành phần hệ thống.
- **[Sơ đồ & Hình ảnh (Diagrams)](./images/architecture/)**: Thư viện các sơ đồ kiến trúc.

### 2. Quyết định Kỹ thuật (ADRs)

- **[Danh sách ADR (Architectural Decision Records)](./adr/README.md)**: Nơi lưu trữ lý do và bối cảnh của mọi quyết định kỹ thuật quan trọng.
  - **[Core Infrastructure](./adr/basic/)**: Các quyết định nền tảng (Giai đoạn 1).
  - **[Module A: Scalability](./adr/module-a/)**: Các quyết định nâng cao về hiệu năng (Giai đoạn 2).

### 3. Module Chuyên sâu (Module A)

- **[Tài liệu Module A (Scalability & Performance)](./module-a/README.md)**:
  - **[Kế hoạch Thực hiện (Plan)](./module-a/PLAN.md)**
  - **[Hướng dẫn Kiểm chứng (Verification Guide)](./module-a/VERIFICATION_GUIDE.md)**
  - **[Kết quả Load Test 1 (Baseline)](./module-a/load-test-1-baseline/README.md)**
  - **[Kết quả Load Test 2 (Tuning)](./module-a/load-test-2-tuning/README.md)**

### 4. Đặc tả Kỹ thuật

- **[API Specifications](./specs/api/)**: Đặc tả giao diện API (OpenAPI/Swagger) giữa Client và Backend.
