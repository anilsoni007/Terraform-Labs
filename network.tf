
resource "aws_subnet" "priv-sub" {
  vpc_id            = aws_vpc.main.id
  for_each          = { for index, az_name in slice(data.aws_availability_zones.az.names, 0, 2) : index => az_name }
  cidr_block        = cidrsubnet(var.vpc_cidr, length(data.aws_availability_zones.az.names) >= 4 ? 4 : 3, each.key)
  availability_zone = each.value

  tags = {
    Name = "private-${each.key}"
  }
}

resource "aws_subnet" "pub-sub" {
  vpc_id            = aws_vpc.main.id
  for_each          = { for index, az_name in slice(data.aws_availability_zones.az.names, 0, 2) : index => az_name }
  cidr_block        = cidrsubnet(var.vpc_cidr, length(data.aws_availability_zones.az.names) > 4 ? 4 : 3, each.key + length(data.aws_availability_zones.az.names))
  availability_zone = each.value
  tags = {
    Name = "public-${each.key}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-tf-vpc"
  }
}


/* 
resource "aws_internet_gateway_attachment" "attach_igw" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id              = aws_vpc.main.id
} 
*/



resource "aws_route_table" "public_rt" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_internet_gateway.gw]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_nat_gateway.ngw]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "private_rt"
  }
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = element([for each_subnet in aws_subnet.pub-sub : each_subnet.id], 0)

  tags = {
    Name = "gw-NAT"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  for_each       = { for i, sub in aws_subnet.priv-sub : i => sub.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_rt_association" {
  for_each       = { for i, sub in aws_subnet.pub-sub : i => sub.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.public_rt.id
}







