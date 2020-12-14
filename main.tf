  provider "aws" {
  region     = "us-east-2"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "firstvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "production"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.firstvpc.id

}

resource "aws_route_table" "production" {
  vpc_id = aws_vpc.firstvpc.id

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "prod"
  }
}

resource "aws_subnet" "secondsubnet" {
  vpc_id = aws_vpc.firstvpc.id
  cidr_block = "10.0.0.0/24"
    
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.firstvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "prodsubnet"
    }
  }

  resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.production.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.firstvpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "webservernic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webservernic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_instance" "web" {
  ami = "ami-0a91cd140a1fc148a"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "ohio-key"

network_interface {
  device_index = 0
  network_interface_id = aws_network_interface.webservernic.id
}
user_data = <<-EOF
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            EOF

}