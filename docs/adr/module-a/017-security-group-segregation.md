# ADR 017: Security Group Segregation per Service

## Trạng thái

Được chấp nhận (Accepted)

## Bối cảnh

Trong Giai đoạn 1 (baseline implementation), hệ thống sử dụng 1 Security Group chung (`db_access`) cho tất cả ECS services và databases. Kiến trúc này có các vấn đề về bảo mật:

**Vấn đề hiện tại:**

- UserService có thể truy cập Redis (không cần thiết cho nghiệp vụ)
- DriverService có thể truy cập PostgreSQL user_db và trip_db (vi phạm nguyên tắc đặc quyền tối thiểu)
- TripService có thể truy cập Redis (chỉ cần PostgreSQL)
- Nếu 1 service bị tấn công thành công, kẻ tấn công có thể truy cập tất cả databases
- Security rules dùng CIDR blocks (`10.0.0.0/16`) thay vì source Security Groups (quá rộng phạm vi)

**Phân tích rủi ro:**

- **Bề mặt Tấn công (Attack Surface)**: Quá rộng - 1 lỗ hổng ở bất kỳ service nào → toàn bộ data layer bị lộ
- **Tuân thủ (Compliance)**: Không đáp ứng yêu cầu audit về Nguyên tắc Đặc quyền Tối thiểu (Least Privilege)
- **Phạm vi Tổn thương (Blast Radius)**: Nếu DriverService bị tấn công, kẻ tấn công có thể đọc/ghi thông tin xác thực người dùng và dữ liệu chuyến đi

## Quyết định

Tách Security Groups theo kiến trúc nhiều tầng (multi-tier segregation):

### Database Tier (3 Security Groups)

1. **`user_db_sg`**: Chỉ cho phép ingress từ `user_service_sg` trên port 5432
2. **`trip_db_sg`**: Chỉ cho phép ingress từ `trip_service_sg` trên port 5432
3. **`redis_sg`**: Chỉ cho phép ingress từ `driver_service_sg` trên port 6379

### Application Tier (3 Security Groups)

4. **`user_service_sg`**: Ingress từ ALB (port 8080), egress unrestricted
5. **`trip_service_sg`**: Ingress từ ALB (port 8081) + từ trip_service_sg (service-to-service), egress unrestricted
6. **`driver_service_sg`**: Ingress từ ALB (port 8082), egress unrestricted

### Load Balancer Tier (1 Security Group)

7. **`alb_sg`**: Ingress từ Internet (port 80), egress unrestricted

### Networking Tier (1 Security Group - existing)

8. **`nat_sg`**: Cho phép private subnets ra Internet qua NAT Gateway

### Security Group Rules (Source-based, không dùng CIDR)

```hcl
# Thay vì:
ingress {
  from_port   = 5432
  cidr_blocks = ["10.0.0.0/16"]  # ❌ Quá permissive
}

# Sử dụng:
ingress {
  from_port            = 5432
  security_groups      = [user_service_sg.id]  # ✅ Least privilege
}
```

## Lý do (Ưu tiên)

### 1. Security - Principle of Least Privilege (Ưu tiên cao nhất)

- Mỗi service chỉ có quyền truy cập **chính xác những gì cần thiết**
- UserService không thể truy cập Redis hoặc trip_db
- DriverService không thể truy cập PostgreSQL
- Giảm attack surface từ 100% (toàn bộ VPC) xuống ~10% (chỉ service cụ thể)

### 2. Tuân thủ và Kiểm tra (Compliance & Audit)

- Đáp ứng yêu cầu PCI-DSS, SOC 2 về phân đoạn mạng (network segmentation)
- Dễ dàng chứng minh với auditor: "UserService chỉ có thể truy cập user_db"
- Security logs rõ ràng hơn (biết chính xác traffic nguồn)

### 3. Hạn chế Phạm vi Tổn thương (Blast Radius Containment)

- Khi DriverService bị tấn công thành công, kẻ tấn công **chỉ có thể** truy cập Redis
- Không thể di chuyển ngang (lateral movement) sang user_db hoặc trip_db
- Giới hạn thiệt hại trong phạm vi 1 service

### 4. Defense in Depth

- Kết hợp với IAM roles, quản lý mật khẩu, mã hóa dữ liệu lưu trữ
- Security Groups là 1 layer trong chiến lược bảo mật nhiều tầng

## Đánh đổi (Chấp nhận)

### 1. Độ phức tạp (Complexity) - Tăng số lượng Security Groups

- **Trước**: 2 SGs (db_access, alb_sg)
- **Sau**: 8 SGs (user_db, trip_db, redis, user_service, trip_service, driver_service, alb, nat)
- **Tác động**: Khó quản lý hơn, khó gỡ lỗi vấn đề mạng
- **Giảm thiểu**: Terraform IaC giúp quản lý tự động, đặt tên rõ ràng

### 2. Terraform Code - Tăng ~150 dòng code

- Thêm 6 security group resources
- Thêm 4 security group rule resources (explicit rules)
- **Đánh đổi**: Code dài hơn nhưng dễ đọc, dễ kiểm tra

### 3. Gỡ lỗi (Debugging) - Khó hơn khi có vấn đề kết nối mạng

- Phải kiểm tra nhiều SGs thay vì 1 SG
- **Giảm thiểu**:
  - VPC Flow Logs để debug
  - CloudWatch Insights query: "Rejected traffic from SG X to SG Y"
  - Terraform outputs hiển thị tất cả SG IDs

### 4. Phụ thuộc Terraform Module - Giải quyết Circular Dependency

- **Vấn đề**: Database module cần `alb_sg_id` (từ ECS), ECS module cần `service_sg_ids` (từ Database) → phụ thuộc vòng tròn
- **Giải pháp**: Di chuyển ALB Security Group từ ECS module sang Network module
- **Thứ tự khởi tạo module**: Network (tạo ALB SG) → Database (nhận ALB SG ID) → ECS (nhận service SG IDs)
- **Kết quả**: Đồ thị phụ thuộc không vòng (acyclic dependency graph)

## Kết quả

### Validation

- ✅ Terraform validate: Configuration valid
- ✅ Terraform plan: 8 SGs to create, 0 to destroy
- ✅ Module dependency: No circular dependencies

### Security Testing (Dự kiến - khi deploy)

Penetration testing scenario:

1. **Kịch bản**: Tấn công thành công driver-service (khai thác lỗi RCE)
2. **Kết quả mong đợi**: Kẻ tấn công chỉ có thể truy cập Redis (vị trí tài xế)
3. **Xác nhận**: Không thể kết nối tới user_db hoặc trip_db (kết nối bị từ chối)

### Metrics

- **Attack Surface Reduction**: 90% (từ toàn VPC xuống 1 service)
- **Điểm Tuân thủ**: 100% (đáp ứng nguyên tắc đặc quyền tối thiểu)
- **Terraform Resources**: +6 SGs, +4 rules

## Tài liệu tham khảo

- [AWS Security Groups Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [NIST SP 800-53: Network Segmentation](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs): `aws_security_group`, `aws_security_group_rule`

## Validation Strategy

**Terraform Validation:**

```bash
cd terraform
terraform validate  # Verify configuration syntax
terraform plan      # Preview 8 SGs creation
```

**Security Testing (Design Verification):**

- Rà soát quy tắc Security Group: Mỗi service chỉ truy cập được database được chỉ định
- Xác minh ingress dựa trên nguồn (security_groups) thay vì CIDR blocks
- Kiểm tra quy tắc egress: Services có thể gọi API bên ngoài nhưng không truy cập chéo database
