# Kết quả Load Test 2: Sau Tối ưu hóa (Tuning)

## 1. Mục tiêu

Kiểm chứng hiệu quả của các giải pháp tối ưu hóa (Connection Pool, Read Replicas, Caching...) so với Baseline.

## 2. Các thay đổi cấu hình (Tuning Configuration)

_(Thành viên thực hiện vui lòng liệt kê các thay đổi cụ thể)_

- **Database Connection Pool**: ... (ví dụ: tăng từ 10 lên 50)
- **Read Replicas**: ... (ví dụ: đã bật)
- **Caching**: ... (ví dụ: cache hit rate đạt bao nhiêu %)

## 3. Kết quả Test

### 3.1. Spike Test (100 VUs)

- **Latency p(95)**: ...
- **Error Rate**: ...

### 3.2. Stress Test (500 VUs)

- **Latency p(95)**: ...
- **Error Rate**: ...
- **Max RPS**: ...

## 4. So sánh với Baseline

| Metric           | Baseline (Phase 1) | Tuning (Phase 2) | Cải thiện (%) |
| :--------------- | :----------------- | :--------------- | :------------ |
| Latency (Spike)  | 1.94s              | ...              | ...           |
| Latency (Stress) | 6.78s              | ...              | ...           |
| Max RPS          | ~56                | ...              | ...           |

## 5. Kết luận

...
