# Lấy thông tin về Region hiện tại đang được cấu hình
data "aws_region" "current" {}

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

# --- Routing cho Public Subnets (Ra Internet qua IGW) ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "uit-go-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway (Cho Private Subnets ra Internet) ---

# Tạo Elastic IP cho NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "uit-go-nat-eip"
  }
}

# Tạo NAT Gateway (đặt tại Public Subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Đặt tại Public Subnet A

  tags = {
    Name = "uit-go-nat-gw"
  }

  # Đảm bảo IGW đã tạo xong trước khi tạo NAT GW
  depends_on = [aws_internet_gateway.gw]
}

# --- Routing cho Private Subnets (Ra Internet qua NAT GW) ---

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "uit-go-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# --- Security Group cho Application Load Balancer ---
# (Moved from ECS module to resolve circular dependency)

resource "aws_security_group" "alb_sg" {
  name        = "uit-go-alb-sg"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Cho phép từ mọi nơi trên Internet
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
