# Khai báo nhà cung cấp (Provider) là AWS
provider "aws" {
  region = "ap-southeast-1" # Singapore
}

# Lấy thông tin về Region hiện tại đang được cấu hình
data "aws_region" "current" {}

# Khai báo Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Định nghĩa Mạng (VPC) ---

# Tạo một VPC mới
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" # Dải địa chỉ IP cho mạng của bạn
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "uit-go-vpc" # Đặt tên cho VPC
  }
}

# Tạo Internet Gateway (để VPC có thể ra internet nếu cần)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "uit-go-igw"
  }
}

# Tạo Subnet công cộng (Public Subnet) - ví dụ: cho Bastion Host sau này
# Chúng ta sẽ tạo 2 cái ở 2 Availability Zone khác nhau cho HA
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${data.aws_region.current.name}a" # Ví dụ: ap-southeast-1a

  tags = {
    Name = "uit-go-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${data.aws_region.current.name}b" # Ví dụ: ap-southeast-1b

  tags = {
    Name = "uit-go-public-b"
  }
}

# Tạo Subnet riêng tư (Private Subnet) - Nơi đặt CSDL
# Chúng ta cũng tạo 2 cái ở 2 AZ khác nhau
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "uit-go-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "uit-go-private-b"
  }
}

# --- Định nghĩa Bảo mật Mạng (Security Groups) ---

# Security Group cho phép truy cập CSDL (RDS & ElastiCache) từ bên trong VPC
resource "aws_security_group" "db_access" {
  name        = "uit-go-db-access-sg"
  description = "Allow DB traffic from within VPC"
  vpc_id      = aws_vpc.main.id

  # Cho phép truy cập Postgres (port 5432) từ bất kỳ IP nào trong VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Chỉ cho phép từ bên trong VPC
  }

  # Cho phép truy cập Redis (port 6379) từ bất kỳ IP nào trong VPC
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Chỉ cho phép từ bên trong VPC
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
#   vpc_id      = aws_vpc.main.id

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
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id] 

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
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

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