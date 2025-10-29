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

# --- Định nghĩa Hạ tầng Triển khai (ECS) ---

# Tạo một ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "uit-go-cluster" # Đặt tên cho cluster

  tags = {
    Name = "uit-go-cluster"
  }
}

# --- Định nghĩa Vai trò IAM cho ECS Tasks ---

# 1. ECS Task Execution Role (Bắt buộc)
# Vai trò này cho phép ECS Agent thực hiện các hành động cần thiết
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "uit-go-ecs-task-execution-role"

  # Chính sách tin cậy (Trust Policy): Cho phép dịch vụ ecs-tasks.amazonaws.com đảm nhận vai trò này
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "uit-go-ecs-task-execution-role"
  }
}

# Đính kèm chính sách quản lý của AWS cho Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  # Chính sách này cung cấp quyền kéo ECR image, ghi CloudWatch logs,...
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# 2. ECS Task Role (Tùy chọn, nhưng cần thiết để truy cập Secrets Manager)
# Vai trò này được code BÊN TRONG container của bạn đảm nhận
resource "aws_iam_role" "ecs_task_role" {
  name = "uit-go-ecs-task-role"

  # Chính sách tin cậy tương tự như trên
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "uit-go-ecs-task-role"
  }
}

# Tạo một Chính sách IAM tùy chỉnh (Inline Policy) cho phép đọc Secrets
resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name = "uit-go-ecs-task-secrets-policy"
  role = aws_iam_role.ecs_task_role.id

  # Chính sách này cho phép đọc giá trị của các secret có tên bắt đầu bằng "uit-go/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          # Thêm quyền kms:Decrypt nếu secret dùng KMS key tùy chỉnh (chúng ta đang dùng key mặc định)
          # "kms:Decrypt" 
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:uit-go/*"
      }
    ]
  })
}

# Lấy thông tin tài khoản AWS hiện tại (để xây dựng ARN chính xác)
data "aws_caller_identity" "current" {}


# --- Định nghĩa ECS Task Definitions ---

# 1. Task Definition cho UserService (Java)
resource "aws_ecs_task_definition" "user_service_task" {
  family                   = "user-service" # Tên định danh
  network_mode             = "awsvpc"       # Bắt buộc cho Fargate
  requires_compatibilities = ["FARGATE"]    # Chỉ định chạy trên Fargate
  cpu                      = "256"          # 0.25 vCPU (chọn giá trị nhỏ cho Free Tier/test)
  memory                   = "512"          # 512 MB RAM (chọn giá trị nhỏ cho Free Tier/test)

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn # Vai trò để ECS Agent chạy
  task_role_arn      = aws_iam_role.ecs_task_role.arn      # Vai trò cho code bên trong container (để đọc Secret)

  # Định nghĩa Container
  container_definitions = jsonencode([
    {
      name      = "user-service" # Tên container
      image     = "nginx:latest" # <-- IMAGE PLACEHOLDER - Sẽ cập nhật sau
      essential = true           # Task sẽ dừng nếu container này lỗi
      portMappings = [
        {
          containerPort = 8080 # Port ứng dụng Java chạy bên trong
          hostPort      = 8080
        }
      ]
      environment = [ # Biến môi trường thường
        { name = "SPRING_DATASOURCE_USERNAME", value = "pgadmin" },
        # Endpoint lấy từ output của RDS instance
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.user_db.address}/${aws_db_instance.user_db.db_name}" } 
      ]
      secrets = [ # Biến môi trường lấy từ Secrets Manager
        { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = aws_secretsmanager_secret.user_db_password.arn }
      ]
      logConfiguration = { # Cấu hình gửi log đến CloudWatch
         logDriver = "awslogs"
         options = {
           "awslogs-group" = "/ecs/user-service", # Tên Log Group
           "awslogs-region" = data.aws_region.current.name,
           "awslogs-stream-prefix" = "ecs"
         }
      }
    }
  ])

  tags = {
    Name = "uit-go-user-service-task"
  }
}

# Tạo CloudWatch Log Group cho UserService
resource "aws_cloudwatch_log_group" "user_service_lg" {
  name = "/ecs/user-service"

  tags = {
    Name = "uit-go-user-service-lg"
  }
}


# 2. Task Definition cho TripService (Java) - Tương tự UserService
resource "aws_ecs_task_definition" "trip_service_task" {
  family                   = "trip-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "trip-service"
      image     = "nginx:latest" # <-- IMAGE PLACEHOLDER
      essential = true
      portMappings = [ { containerPort = 8081, hostPort = 8081 } ]
      environment = [
        { name = "SPRING_DATASOURCE_USERNAME", value = "pgadmin" },
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.trip_db.address}/${aws_db_instance.trip_db.db_name}" },
        # URL của các service khác (sẽ dùng Service Discovery hoặc Load Balancer sau)
        { name = "USER_SERVICE_URL", value = "http://user-service.local:8080" }, # Tạm thời
        { name = "DRIVER_SERVICE_URL", value = "http://driver-service.local:8082" } # Tạm thời
      ]
      secrets = [
        { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = aws_secretsmanager_secret.trip_db_password.arn }
      ]
      logConfiguration = {
         logDriver = "awslogs"
         options = {
           "awslogs-group" = "/ecs/trip-service",
           "awslogs-region" = data.aws_region.current.name,
           "awslogs-stream-prefix" = "ecs"
         }
      }
    }
  ])

  tags = {
    Name = "uit-go-trip-service-task"
  }
}

# Tạo CloudWatch Log Group cho TripService
resource "aws_cloudwatch_log_group" "trip_service_lg" {
  name = "/ecs/trip-service"
  tags = { Name = "uit-go-trip-service-lg" }
}


# 3. Task Definition cho DriverService (Node.js)
resource "aws_ecs_task_definition" "driver_service_task" {
  family                   = "driver-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn # Cần quyền đọc Secret nếu dùng sau này

  container_definitions = jsonencode([
    {
      name      = "driver-service"
      image     = "nginx:latest" # <-- IMAGE PLACEHOLDER
      essential = true
      portMappings = [ { containerPort = 8082, hostPort = 8082 } ]
      environment = [
        # Endpoint lấy từ output của ElastiCache cluster
        { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.redis_cluster.cache_nodes[0].address}:${aws_elasticache_cluster.redis_cluster.cache_nodes[0].port}" }
      ]
      # secrets = [] # Tạm thời chưa cần secret
      logConfiguration = {
         logDriver = "awslogs"
         options = {
           "awslogs-group" = "/ecs/driver-service",
           "awslogs-region" = data.aws_region.current.name,
           "awslogs-stream-prefix" = "ecs"
         }
      }
    }
  ])

  tags = {
    Name = "uit-go-driver-service-task"
  }
}

# Tạo CloudWatch Log Group cho DriverService
resource "aws_cloudwatch_log_group" "driver_service_lg" {
  name = "/ecs/driver-service"
  tags = { Name = "uit-go-driver-service-lg" }
}

# --- Định nghĩa Application Load Balancer (ALB) ---

# Tạo Security Group cho ALB: Cho phép traffic HTTP (port 80) từ Internet
resource "aws_security_group" "alb_sg" {
  name        = "uit-go-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Cho phép từ mọi nơi
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uit-go-alb-sg"
  }
}

# Tạo Application Load Balancer
resource "aws_lb" "main" {
  name               = "uit-go-alb"
  internal           = false # ALB này hướng ra Internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # Đặt ALB vào các public subnets để có thể truy cập từ Internet
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] 

  enable_deletion_protection = false # Tắt bảo vệ xóa (cho đồ án)

  tags = {
    Name = "uit-go-alb"
  }
}

# Tạo Listener cho ALB trên port 80 (HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Hành động mặc định: Trả về lỗi 404 nếu không khớp rule nào
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# --- Định nghĩa Target Groups & ECS Services ---

# Hàm tạo lặp (sử dụng for_each để tránh lặp code)
locals {
  services = {
    user = {
      port            = 8080
      task_definition = aws_ecs_task_definition.user_service_task.arn
      path_pattern    = "/users*" # Các request đến /users... sẽ vào service này
    },
    trip = {
      port            = 8081
      task_definition = aws_ecs_task_definition.trip_service_task.arn
      path_pattern    = "/trips*" # Các request đến /trips... sẽ vào service này
    },
    driver = {
      port            = 8082
      task_definition = aws_ecs_task_definition.driver_service_task.arn
      path_pattern    = "/drivers*" # Các request đến /drivers... sẽ vào service này
    }
  }
}

# Tạo Target Group và ECS Service cho mỗi service trong locals.services
resource "aws_lb_target_group" "service_tg" {
  for_each = local.services

  name        = "uit-go-${each.key}-tg"
  port        = each.value.port # Port của container
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Bắt buộc cho Fargate

  health_check {
    path                = "/" # Đường dẫn kiểm tra sức khỏe đơn giản
    protocol            = "HTTP"
    matcher             = "200" # Mong đợi mã 200 OK
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "uit-go-${each.key}-tg"
  }
}

resource "aws_ecs_service" "main" {
  for_each = local.services

  name            = "uit-go-${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = each.value.task_definition
  desired_count   = 1 # Chạy 1 container cho mỗi service
  launch_type     = "FARGATE"

  network_configuration {
    # Đặt container vào private subnets
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id] 
    security_groups = [aws_security_group.db_access.id] # Tạm dùng SG của DB (cho phép ra ngoài gọi API khác)
    assign_public_ip = false # Không cần IP public cho container Fargate
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service_tg[each.key].arn
    container_name   = "${each.key}-service" # Phải khớp tên container trong Task Definition
    container_port   = each.value.port
  }

  # Đảm bảo Service được tạo sau Listener
  depends_on = [aws_lb_listener.http]
}

# Tạo Listener Rule cho ALB để định tuyến request đến từng Target Group
resource "aws_lb_listener_rule" "service_rule" {
  for_each = local.services

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(keys(local.services), each.key) # Ưu tiên dựa trên thứ tự

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_tg[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern] # Định tuyến dựa trên đường dẫn URL
    }
  }
}

# --- (Hoàn thành định nghĩa ECS Services & ALB) ---

# --- Định nghĩa Elastic Container Registry (ECR) ---

# Tạo ECR Repository cho mỗi service
resource "aws_ecr_repository" "service_ecr" {
  for_each = local.services # Dùng lại map 'services' đã định nghĩa

  name = "uit-go/${each.key}-service" # Tên repo, ví dụ: uit-go/user-service

  image_tag_mutability = "MUTABLE" # Cho phép ghi đè tag (ví dụ: 'latest')

  image_scanning_configuration {
    scan_on_push = true # Tự động quét lỗ hổng bảo mật khi đẩy image
  }

  tags = {
    Name = "uit-go-${each.key}-service-ecr"
  }
}

# --- (Hoàn thành định nghĩa ECR) ---