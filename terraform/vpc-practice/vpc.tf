resource "aws_vpc" "main" {
	cidr_block = "10.0.0.0/16"

	tags = {
		Name = "syungg-terraform"
	}
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "terraform-syungg-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "terraform-syungg-private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-syungg-igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id

  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gw"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-syungg-public-rt"
  }
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-syungg-private-rt"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "route_table_association_private" {
  subnet_id = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_route" "public_route_rule" {
  route_table_id = aws_route_table.route_table_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route" "private_nat_route_rule" {
  route_table_id = aws_route_table.route_table_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw.id
}
