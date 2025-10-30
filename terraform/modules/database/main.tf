# --- Định nghĩa Bảo mật Mạng (Security Groups) ---

# Security Group cho phép truy cập CSDL (RDS & ElastiCache) từ bên trong VPC
resource "aws_security_group" "db_access" {
  name        = "uit-go-db-access-sg"
  description = "Allow DB traffic from within VPC"
  vpc_id      = var.vpc_id

  # Cho phép truy cập Postgres (port 5432) từ bất kỳ IP nào trong VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] # Chỉ cho phép từ bên trong VPC
  }

  # Cho phép truy cập Redis (port 6379) từ bất kỳ IP nào trong VPC
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] # Chỉ cho phép từ bên trong VPC
  }

  # Cho phép tất cả traffic đi ra (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-db-access-sg"
  }
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
  name       = "uit-go-rds-subnet-group"
  # Chỉ định ID của 2 private subnets
  subnet_ids = var.private_subnet_ids 

  tags = {
    Name = "uit-go-rds-subnet-group"
  }
}

# --- Định nghĩa CSDL PostgreSQL (RDS) ---

# Tạo CSDL Postgres cho UserService
resource "aws_db_instance" "user_db" {
  identifier             = "uit-go-user-db"
  allocated_storage      = 20 # Dung lượng ổ đĩa (GB) - tối thiểu cho Free Tier
  engine                 = "postgres"
  engine_version         = "15" # Chọn phiên bản Postgres mong muốn
  instance_class         = "db.t3.micro" # Loại máy chủ nhỏ (kiểm tra Free Tier eligibility)

  db_name                = "uit_user_db" # Tên CSDL
  username               = "pgadmin" # Username master
  manage_master_user_password = true 
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name # Đặt CSDL vào private subnets
  vpc_security_group_ids = [aws_security_group.db_access.id] # Áp dụng SG đã tạo

  skip_final_snapshot    = true # Bỏ qua snapshot cuối cùng khi xóa (cho đồ án)
  publicly_accessible    = false # KHÔNG cho phép truy cập từ Internet

  tags = {
    Name = "uit-go-user-db"
  }
}

# Tạo CSDL Postgres cho TripService
resource "aws_db_instance" "trip_db" {
  identifier             = "uit-go-trip-db"
  allocated_storage      = 20 
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"

  db_name                = "uit_trip_db" 
  username               = "pgadmin" 
  manage_master_user_password = true 
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name 
  vpc_security_group_ids = [aws_security_group.db_access.id]

  skip_final_snapshot    = true 
  publicly_accessible    = false 

  tags = {
    Name = "uit-go-trip-db"
  }
}

# --- Định nghĩa Subnet Group và Cluster cho ElastiCache (Redis) ---

# Tạo một Subnet Group cho ElastiCache, sử dụng 2 private subnets
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "uit-go-redis-subnet-group"
  # Chỉ định ID của 2 private subnets
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "uit-go-redis-subnet-group"
  }
}

# Tạo ElastiCache Redis Cluster (1 node)
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "uit-go-redis-cluster"
  engine               = "redis"
  engine_version       = "7.0" # Chọn phiên bản Redis (kiểm tra phiên bản mới nhất)
  node_type            = "cache.t3.micro" # Loại node nhỏ (kiểm tra Free Tier eligibility)
  num_cache_nodes      = 1 # Chỉ cần 1 node cho đồ án

  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name # Đặt Redis vào private subnets
  security_group_ids = [aws_security_group.db_access.id] # Áp dụng SG đã tạo (cho phép truy cập từ VPC)
  port                 = 6379 # Port mặc định của Redis

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
  name = "uit-go/trip-db/password"
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
