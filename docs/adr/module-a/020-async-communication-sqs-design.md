# ADR 020: Async Communication với Amazon SQS (Design Only)

## Trạng thái

Đã Phân tích (Chỉ Thiết kế - Chưa Triển khai)

**Lý do**: ADR này ghi lại phân tích so sánh giữa kiến trúc đồng bộ (REST) và bất đồng bộ (SQS). Quyết định: Giữ REST cho yêu cầu real-time, SQS không triển khai do trade-off latency.

## Bối cảnh

Hiện tại TripService gọi DriverService qua REST API (synchronous HTTP):

**Current Flow (Synchronous):**

```
User Request → TripService → HTTP GET /drivers/nearby → DriverService
                ↓ (blocking)
            Wait for response (200ms)
                ↓
            Create trip with driver_id
                ↓
            Return to user (500ms total)
```

**Vấn đề của Synchronous Communication:**

### 1. Blocking I/O (Chặn I/O) - Lãng phí Luồng (Thread)

- TripService thread bị chặn (block) trong 200ms chờ DriverService response
- Với 10 concurrent requests → 10 threads bị chặn
- HikariCP thread pool (max=5) → bão hòa (saturation) → requests xếp hàng
- **Nút thắt (Bottleneck)**: TripService chỉ chịu được ~200 RPS

### 2. Timeout Cascade - Lỗi Lan truyền Theo Dây chuyền

```
DriverService chậm/down (timeout 5s)
    ↓
TripService request timeout
    ↓
User nhận lỗi 503 Service Unavailable
    ↓
Retry storm (cơn bão retry) → TripService bị quá tải (overload)
```

### 3. Tight Coupling - Phụ thuộc Dịch vụ

- TripService **phải biết** DriverService endpoint
- DriverService down → TripService degraded
- Deployment của DriverService → rollback TripService nếu có thay đổi không tương thích

### 4. Khả năng Mở rộng Hạn chế (Limited Scalability)

**Kết quả Load Testing:**

- 1 TripService task = 100 RPS tối đa
- Auto-scale lên 10 tasks = 1000 RPS tối đa
- DriverService nút thắt (bottleneck) = 500 RPS (do độ trễ Redis)
- **Nút thắt Hệ thống**: 500 RPS (giới hạn bởi dịch vụ yếu nhất)

## Quyết định (Thiết kế - Không Triển khai)

Phân tích kiến trúc bất đồng bộ với SQS, nhưng quyết định giữ REST cho core flows. **Lý do**: Trade-off analysis cho thấy SQS cải thiện throughput nhưng tăng latency không chấp nhận được cho real-time operations.

### Kiến trúc Đề xuất: Hướng Sự kiện với Amazon SQS

```
┌─────────────┐                    ┌──────────────────┐
│    User     │                    │  SQS Queue       │
│   Request   │                    │  driver-requests │
└──────┬──────┘                    └────────┬─────────┘
       │                                    │
       v                                    │
┌──────────────┐                           │
│ TripService  │                           │
│              │                           │
│ 1. Publish   │───────────────────────────┘
│    event     │    FindDriverRequest
│              │    { lat, lng, trip_id }
│ 2. Return    │
│    202       │
│    Accepted  │
└──────┬───────┘
       │                            ┌──────────────────┐
       │                            │  SQS Queue       │
       │                            │ driver-responses │
       │                            └────────┬─────────┘
       │                                     │
       │                                     │
       v                            ┌────────v─────────┐
┌──────────────┐                    │ DriverService    │
│ Poll SQS     │◄───────────────────│                  │
│ Consume      │  DriversFoundEvent │ 1. Poll requests │
│ Response     │  { drivers: [...] }│ 2. Find drivers  │
│              │                    │ 3. Publish resp  │
│ 3. Update    │                    └──────────────────┘
│    Trip      │
└──────────────┘
```

### Components

#### 1. SQS Queues

```hcl
# Request queue: TripService → DriverService
resource "aws_sqs_queue" "driver_requests" {
  name                       = "uit-go-driver-requests"
  delay_seconds              = 0
  visibility_timeout_seconds = 30  # Giới hạn thời gian xử lý
  message_retention_seconds  = 1209600  # 14 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.driver_requests_dlq.arn
    maxReceiveCount     = 3  # Retry 3 lần trước khi vào DLQ
  })
}

# Response queue: DriverService → TripService
resource "aws_sqs_queue" "driver_responses" {
  name                       = "uit-go-driver-responses"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.driver_responses_dlq.arn
    maxReceiveCount     = 3
  })
}

# Dead Letter Queues (DLQ) - Tin nhắn thất bại
resource "aws_sqs_queue" "driver_requests_dlq" {
  name = "uit-go-driver-requests-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "driver_responses_dlq" {
  name = "uit-go-driver-responses-dlq"
  message_retention_seconds = 1209600
}
```

#### 2. Message Schema

**FindDriverRequest (TripService → DriverService):**

```json
{
  "messageId": "uuid-1234",
  "tripId": 789,
  "userId": 123,
  "pickupLocation": {
    "lat": 10.762622,
    "lng": 106.660172
  },
  "timestamp": "2024-11-20T10:30:00Z",
  "timeout": 5000 // Max processing time (ms)
}
```

**DriversFoundEvent (DriverService → TripService):**

```json
{
  "messageId": "uuid-1234", // Giống request (tương quan)
  "tripId": 789,
  "drivers": [
    { "id": 456, "name": "Nguyen Van A", "distance": 1.2, "rating": 4.8 },
    { "id": 457, "name": "Tran Van B", "distance": 1.5, "rating": 4.9 }
  ],
  "timestamp": "2024-11-20T10:30:02Z",
  "processingTime": 2000 // ms
}
```

#### 3. Application Code (Conceptual)

**TripService - Producer:**

```java
@Service
public class TripService {

    @Autowired
    private SqsTemplate sqsTemplate;

    public Trip createTrip(CreateTripRequest request) {
        // 1. Create trip với status PENDING
        Trip trip = tripRepository.save(new Trip(
            userId,
            TripStatus.PENDING,
            pickupLocation
        ));

        // 2. Publish event to SQS
        FindDriverRequest event = new FindDriverRequest(
            trip.getId(),
            request.getUserId(),
            request.getPickupLocation()
        );
        sqsTemplate.send("uit-go-driver-requests", event);

        // 3. Return ngay (202 Accepted) - KHÔNG chờ driver
        return trip;  // Status: PENDING
    }

    // Consumer - Poll response queue
    @SqsListener("uit-go-driver-responses")
    public void handleDriversFound(DriversFoundEvent event) {
        Trip trip = tripRepository.findById(event.getTripId());

        // Update trip với drivers found
        trip.setAvailableDrivers(event.getDrivers());
        trip.setStatus(TripStatus.DRIVER_ASSIGNED);
        tripRepository.save(trip);

        // Send notification to user (WebSocket, FCM, etc.)
        notificationService.notifyUser(trip.getUserId(), "Driver found!");
    }
}
```

**DriverService - Consumer & Producer:**

```javascript
// Consumer - Poll request queue
const consumer = Consumer.create({
  queueUrl:
    "https://sqs.ap-southeast-1.amazonaws.com/.../uit-go-driver-requests",
  handleMessage: async (message) => {
    const request = JSON.parse(message.Body);

    // Find nearby drivers from Redis
    const drivers = await redisClient.georadius(
      "driver_locations",
      request.pickupLocation.lng,
      request.pickupLocation.lat,
      5, // 5km radius
      "km",
      "WITHDIST",
      "ASC",
      "COUNT",
      10
    );

    // Publish response to SQS
    await sqsClient.sendMessage({
      QueueUrl:
        "https://sqs.ap-southeast-1.amazonaws.com/.../uit-go-driver-responses",
      MessageBody: JSON.stringify({
        messageId: request.messageId,
        tripId: request.tripId,
        drivers: drivers.map((d) => ({ id: d.id, distance: d.distance })),
      }),
    });
  },
});

consumer.start();
```

## Lý do (Ưu tiên)

### 1. Throughput - Scale lên Hàng triệu Tin nhắn/Ngày (Ưu tiên cao nhất)

**SQS Limits:**

- Standard queue: Unlimited throughput (millions req/sec)
- FIFO queue: 3000 messages/sec (300 batches/sec × 10 messages)

**Comparison:**
| Metric | REST (Current) | SQS (Proposed) | Improvement |
|-------------------|----------------|----------------|-------------|
| Throughput (RPS) | 200 | 5000+ | **+2400%** |
| Max messages/day | 17M | Unlimited | **∞** |

### 2. Decoupling - Độc lập Dịch vụ

**Current (REST):**

- TripService → DriverService dependency (gắn kết chặt)
- DriverService down → TripService degraded

**Proposed (SQS):**

- TripService publishes event → returns immediately
- DriverService consumes event asynchronously
- **DriverService down**: Messages queue up, no impact on TripService

**Benefits:**

- Triển khai độc lập (không cần phối hợp rollout)
- Mở rộng độc lập (TripService scale to 10 tasks, DriverService scale to 5 tasks)

### 3. Resilience - Tự động Thử lại & Hàng đợi Thư chết

**Failure Scenario:**

```
DriverService crashes khi xử lý message
    ↓
Message không bị xóa (thời gian hiển thị)
    ↓
Message reappears sau 30s
    ↓
DriverService retry (max 3 lần)
    ↓
Sau 3 lần thất bại → DLQ
    ↓
CloudWatch Alarm → investigate DLQ
```

**vs REST:**

- Request timeout → 503 error → user retry → cơn bão thử lại

### 4. Cost Efficiency - Trả tiền theo Tin nhắn

**SQS Pricing:**

- $0.40 per 1M requests (first 1M free/month)
- 1M requests/day = $12/month

**vs Auto-scale ECS tasks:**

- 10 tasks × $0.05/hour × 24 × 30 = $360/month
- SQS cho phép giảm ECS tasks (async processing) → $150/month
- **Net savings**: $210/month (58%)

## Đánh đổi (Chấp nhận)

### 1. Latency - Tăng từ 500ms → 3-5s (ĐÁNH ĐỔI QUAN TRỌNG) ❌

**Breakdown:**

```
REST (Current):
User request → TripService (50ms)
            → HTTP call DriverService (200ms)
            → Response (50ms)
Total: 300ms (thời gian thực)

SQS (Proposed):
User request → TripService publish SQS (50ms)
            → Return 202 Accepted (50ms) ← User sees "Finding driver..."
            → SQS delivery (100ms)
            → DriverService poll (1-20s, depends on polling interval)
            → DriverService process (200ms)
            → Publish response (100ms)
            → TripService poll (1-20s)
            → Update trip (50ms)
            → Notify user WebSocket (50ms)
Total: 3-5s (nhất quán cuối cùng)
```

**User Experience Impact:**

- **Current**: User clicks "Request trip" → sees driver immediately (500ms)
- **Proposed**: User clicks → sees "Finding driver..." → wait 3-5s → notification "Driver found!"

**Is this acceptable?**

- For ride-hailing: **QUESTIONABLE** (users expect instant match)
- For food delivery: **ACCEPTABLE** (users OK với "Đang tìm tài xế...")
- For background jobs: **EXCELLENT** (không cần real-time)

### 2. Complexity - Quản lý Sự kiện, Tính Idempotency, Thứ tự (Chấp nhận được)

**Event Management:**

- Phải track tương quan tin nhắn (messageId)
- Phải handle tin nhắn trùng lặp (SQS at-least-once delivery)
- Phải implement khóa idempotency

**Idempotency Example:**

```java
@SqsListener("uit-go-driver-responses")
@Transactional
public void handleDriversFound(DriversFoundEvent event) {
    // Check if message already processed
    if (processedMessageRepository.exists(event.getMessageId())) {
        logger.warn("Duplicate message: {}", event.getMessageId());
        return;  // Skip processing
    }

    // Process message
    Trip trip = tripRepository.findById(event.getTripId());
    trip.setDrivers(event.getDrivers());
    tripRepository.save(trip);

    // Mark as processed
    processedMessageRepository.save(new ProcessedMessage(event.getMessageId()));
}
```

**Ordering:**

- SQS Standard: Không bảo đảm thứ tự (messages arrive out of order)
- SQS FIFO: Bảo đảm thứ tự, nhưng throughput thấp hơn (3000 msg/sec)

### 3. Eventual Consistency - Thách thức Trải nghiệm Người dùng ❌

**Scenario:**

```
T=0s:   User clicks "Request trip"
T=0.1s: TripService returns { tripId: 789, status: "PENDING" }
T=0.1s: User sees "Finding driver..." (spinner)
T=3s:   DriverService finds drivers
T=3.5s: TripService receives response, updates trip
T=3.5s: User receives WebSocket notification "Driver found!"
```

**Trade-off:**

- **Benefit**: Decoupling, scalability
- **Cost**: +3s latency → worse UX for real-time use case

**Lựa chọn Thay thế:**

- Giữ REST cho real-time operations (create trip, driver matching)
- Dùng SQS cho batch operations (notifications, analytics, reporting)

### 4. Monitoring & Debugging - Khó Theo dõi hơn (Chấp nhận được)

**Theo dõi Phân tán:**

- REST: 1 HTTP request → easy to trace (X-Request-ID header)
- SQS: 3 hops (publish → queue → consume → publish → consume) → hard to trace

**Giảm thiểu:**

- AWS X-Ray: Distributed tracing for SQS
- CloudWatch Logs Insights: Query by messageId
- ID Tương quan: Truyền messageId qua tất cả hops

## Kết quả (Dự kiến - Nếu Implement)

### Performance Metrics

| Metric                  | REST (Current) | SQS (Proposed) | Change        |
| ----------------------- | -------------- | -------------- | ------------- |
| Throughput (RPS)        | 200            | 5000+          | **+2400%**    |
| Latency p50             | 300ms          | 3000ms         | **+900%** ❌  |
| Latency p95             | 500ms          | 5000ms         | **+900%** ❌  |
| ECS Tasks Needed (peak) | 10             | 3              | **-70%** ✅   |
| Cost (monthly)          | $360           | $150           | **-58%** ✅   |
| Availability            | 99.5%          | 99.99%         | **+0.49%** ✅ |

### Cost Breakdown

**Current (REST):**

- 10 ECS tasks × $0.05/hour × 24 × 30 = $360/month

**Proposed (SQS):**

- 3 ECS tasks × $0.05/hour × 24 × 30 = $108/month
- SQS: 100M requests/month × $0.40/1M = $40/month
- **Total**: $148/month
- **Savings**: $212/month (59%)

## Phân tích Trade-offs: REST vs SQS

### Lý do Không Triển khai SQS

### 1. Yêu cầu Latency - Real-time là Tối quan trọng

- Ứng dụng ride-hailing yêu cầu driver matching tức thời (< 1s)
- +3s latency không chấp nhận được cho trải nghiệm người dùng
- Focus: Performance & Scalability với real-time constraints

### 2. REST + Circuit Breaker Đáp ứng Yêu cầu

**Các tối ưu hiện tại:**

- Auto-scaling: 200 RPS → 450 RPS ✅
- Circuit Breaker (Resilience4j): Ngăn chặn cascading failures ✅
- Read Replica + Caching: Latency 800ms → 120ms ✅

**Kết luận**: REST đạt được mục tiêu (450 RPS, 99% uptime)

### 3. Future Roadmap - SQS cho Production

**Dùng SQS cho:**

- **Batch operations**: Gửi thông báo tới 10,000 người dùng
- **Analytics**: Tổng hợp dữ liệu chuyến đi ban đêm
- **Reporting**: Tạo báo cáo hiệu suất tài xế hàng tháng

**Giữ REST cho:**

- **Real-time operations**: Tạo chuyến đi, khớp tài xế, cập nhật trạng thái
- **User-facing APIs**: Mọi API yêu cầu response < 500ms

## Chiến lược Xác thực

**Phân tích Hoàn thành:**

- So sánh kiến trúc đồng bộ (REST) vs bất đồng bộ (SQS)
- Xác định trade-offs: Throughput vs Latency, Decoupling vs Complexity
- Lượng hóa tác động: +2400% throughput nhưng +3s latency

**Quyết định Được Bảo vệ:**

- **Đã chọn**: REST + Circuit Breaker
- **Đã loại bỏ**: SQS (mặc dù throughput cao hơn)
- **Lý do**: Yêu cầu UX (< 500ms) quan trọng hơn throughput

**Terraform Code Status:\*\***

- SQS queue definitions included in ADR (design reference)
- Not added to actual Terraform modules (not implemented)
- Can be referenced for future consideration

## References & Learning

This analysis references:

- [Amazon SQS Documentation](https://docs.aws.amazon.com/sqs/)
- [AWS Architecture: Event-Driven Microservices](https://aws.amazon.com/event-driven-architecture/)
- Martin Fowler: [Event-Driven Architecture](https://martinfowler.com/articles/201701-event-driven.html)
- Sam Newman: Building Microservices (Chapter 4: Integration)
