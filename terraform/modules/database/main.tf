# --- Định nghĩa Bảo mật Mạng (Security Groups) - SEGREGATED ---

# 1. Security Group cho User DB (chỉ cho user-service truy cập)
resource "aws_security_group" "user_db_sg" {
  name        = "uit-go-user-db-sg"
  description = "Allow access to user DB only from user-service"
  vpc_id      = var.vpc_id

  # Không có ingress rule ở đây - sẽ được thêm từ user_service_sg

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-user-db-sg"
  }
}

# 2. Security Group cho Trip DB (chỉ cho trip-service truy cập)
resource "aws_security_group" "trip_db_sg" {
  name        = "uit-go-trip-db-sg"
  description = "Allow access to trip DB only from trip-service"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-trip-db-sg"
  }
}

# 3. Security Group cho Redis (chỉ cho driver-service truy cập)
resource "aws_security_group" "redis_sg" {
  count       = var.enable_redis ? 1 : 0
  name        = "uit-go-redis-sg"
  description = "Allow access to Redis only from driver-service"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-redis-sg"
  }
}

# 4. Security Group cho User Service (ECS Tasks)
resource "aws_security_group" "user_service_sg" {
  name        = "uit-go-user-service-sg"
  description = "Security group for user-service ECS tasks"
  vpc_id      = var.vpc_id

  # Cho phép traffic từ ALB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_sg_id] # Nhận từ ECS module
  }

  # Cho phép tất cả traffic đi ra
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-user-service-sg"
  }
}

# 5. Security Group cho Trip Service (ECS Tasks)
resource "aws_security_group" "trip_service_sg" {
  name        = "uit-go-trip-service-sg"
  description = "Security group for trip-service ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-trip-service-sg"
  }
}

# 6. Security Group cho Driver Service (ECS Tasks)
resource "aws_security_group" "driver_service_sg" {
  name        = "uit-go-driver-service-sg"
  description = "Security group for driver-service ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-driver-service-sg"
  }
}

# --- Security Group Rules (Least Privilege Access) ---

# Rule: user-service → user_db (port 5432)
resource "aws_security_group_rule" "user_service_to_user_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.user_service_sg.id
  security_group_id        = aws_security_group.user_db_sg.id
  description              = "Allow user-service to access user_db"
}

# Rule: trip-service → trip_db (port 5432)
resource "aws_security_group_rule" "trip_service_to_trip_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.trip_service_sg.id
  security_group_id        = aws_security_group.trip_db_sg.id
  description              = "Allow trip-service to access trip_db"
}

# Rule: driver-service → redis (port 6379)
resource "aws_security_group_rule" "driver_service_to_redis" {
  count                    = var.enable_redis ? 1 : 0
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.driver_service_sg.id
  security_group_id        = var.enable_redis ? aws_security_group.redis_sg[0].id : aws_security_group.driver_service_sg.id
  description              = "Allow driver-service to access Redis"
}

# Rule: trip-service → driver-service (service-to-service communication)
resource "aws_security_group_rule" "trip_to_driver_service" {
  type                     = "ingress"
  from_port                = 8082
  to_port                  = 8082
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.trip_service_sg.id
  security_group_id        = aws_security_group.driver_service_sg.id
  description              = "Allow trip-service to call driver-service"
}

# (Tùy chọn) Security Group cho Bastion Host (nếu bạn cần truy cập CSDL từ máy)
# resource "aws_security_group" "bastion_ssh" {
#   name        = "uit-go-bastion-ssh-sg"
#   description = "Allow SSH access from my IP"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["YOUR_PUBLIC_IP/32"] # <-- THAY BẰNG IP CÔNG CỘNG CỦA BẠN
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "uit-go-bastion-ssh-sg"
#   }
# }

# --- Định nghĩa Nhóm Subnet cho RDS ---

# Tạo một Subnet Group cho RDS, sử dụng 2 private subnets đã tạo
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "uit-go-rds-subnet-group"
  # Chỉ định ID của 2 private subnets
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "uit-go-rds-subnet-group"
  }
}

# --- Định nghĩa CSDL PostgreSQL (RDS) ---

# Tạo CSDL Postgres cho UserService
resource "aws_db_instance" "user_db" {
  count             = var.enable_rds ? 1 : 0
  identifier        = "uit-go-user-db"
  allocated_storage = 20 # Dung lượng ổ đĩa (GB) - tối thiểu cho Free Tier
  engine            = "postgres"
  engine_version    = "15"          # Chọn phiên bản Postgres mong muốn
  instance_class    = "db.t3.micro" # Loại máy chủ nhỏ (kiểm tra Free Tier eligibility)

  db_name                     = "uit_user_db" # Tên CSDL
  username                    = "pgadmin"     # Username master
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name # Đặt CSDL vào private subnets
  vpc_security_group_ids      = [aws_security_group.user_db_sg.id]        # Sử dụng SG riêng cho user_db

  skip_final_snapshot = true  # Bỏ qua snapshot cuối cùng khi xóa (cho đồ án)
  publicly_accessible = false # KHÔNG cho phép truy cập từ Internet

  tags = {
    Name = "uit-go-user-db"
  }
}

# Tạo CSDL Postgres cho TripService
resource "aws_db_instance" "trip_db" {
  count             = var.enable_rds ? 1 : 0
  identifier        = "uit-go-trip-db"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"

  db_name                     = "uit_trip_db"
  username                    = "pgadmin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.trip_db_sg.id] # Sử dụng SG riêng cho trip_db

  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name = "uit-go-trip-db"
  }
}

# --- RDS Read Replica for Trip DB ---
# Read replica để phân tải read queries (trip history, analytics)

resource "aws_db_instance" "trip_db_replica" {
  count              = var.enable_rds && var.enable_read_replica ? 1 : 0
  identifier          = "uit-go-trip-db-replica"
  replicate_source_db = aws_db_instance.trip_db[0].identifier

  # Same instance class as primary (có thể nhỏ hơn nếu cần)
  instance_class = "db.t3.micro"

  # MUST be in different AZ for high availability
  availability_zone = var.read_replica_az # Khác với primary (ví dụ: ap-southeast-1b)

  # Inherit settings from primary
  publicly_accessible = false
  skip_final_snapshot = true

  # Apply same security group (cho phép truy cập từ trip-service)
  vpc_security_group_ids = [aws_security_group.trip_db_sg.id]

  tags = {
    Name = "uit-go-trip-db-replica"
  }
}

# --- Định nghĩa Subnet Group và Cluster cho ElastiCache (Redis) ---

# Tạo một Subnet Group cho ElastiCache, sử dụng 2 private subnets
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  count = var.enable_redis ? 1 : 0
  name = "uit-go-redis-subnet-group"
  # Chỉ định ID của 2 private subnets
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "uit-go-redis-subnet-group"
  }
}

# Tạo ElastiCache Redis Cluster (1 node)
resource "aws_elasticache_cluster" "redis_cluster" {
  count           = var.enable_redis ? 1 : 0
  cluster_id      = "uit-go-redis-cluster"
  engine          = "redis"
  engine_version  = "7.0"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1

  subnet_group_name  = var.enable_redis ? aws_elasticache_subnet_group.redis_subnet_group[0].name : ""
  security_group_ids = var.enable_redis ? [aws_security_group.redis_sg[0].id] : []
  port               = 6379

  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"

  tags = {
    Name = "uit-go-redis-cluster"
  }
}

# --- (Hoàn thành định nghĩa CSDL) ---

# --- Quản lý Mật khẩu An toàn (AWS Secrets Manager) ---

# Tạo một secret để lưu mật khẩu cho User DB
resource "aws_secretsmanager_secret" "user_db_password" {
  name = "uit-go/user-db/password"
  # Terraform sẽ tự động tạo một mật khẩu ngẫu nhiên mạnh
  recovery_window_in_days = 0 # Xóa ngay lập tức khi destroy (cho đồ án)
}

resource "aws_secretsmanager_secret_version" "user_db_password_version" {
  secret_id     = aws_secretsmanager_secret.user_db_password.id
  secret_string = random_password.user_db_password.result
}

resource "random_password" "user_db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Tạo một secret để lưu mật khẩu cho Trip DB
resource "aws_secretsmanager_secret" "trip_db_password" {
  name                    = "uit-go/trip-db/password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "trip_db_password_version" {
  secret_id     = aws_secretsmanager_secret.trip_db_password.id
  secret_string = random_password.trip_db_password.result
}

resource "random_password" "trip_db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
