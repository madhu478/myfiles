# creating vpc for 3-tier architecure

resource "aws_vpc"  "3tier" {

       cidr_block           = "10.0.0.0/16"
       enable_dns_support   = true
       enable_dns_hostnames = true
       instance_tenancy = "default"


       tags = {
          Name      = "Three Tier VPC"
          BuildWith = "terraform"
  }
}


#Creating Internet Gateway and attahced to vpc

resource "aws_internet_gateway" "gw" {
  vpc_id = "${ aws_vpc.3tier.id }"

  tags = {
     Name      = "Internet Gateway"
     BuildWith = "terraform"
  }
}


#Creating Public subnets

resource "aws_subnet" "main1" {
  vpc_id     = "${aws_vpc.3tier.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone="us-east-2a"
 

  tags = {
    Name      = "Public Subnet1"
    BuildWith = "terraform"
  }
}

resource "aws_subnet" "main2" {
  vpc_id     = "${aws_vpc.3tier.id}"
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone="us-east-2c"

  tags = {
    Name      = "Public Subnet2"
    BuildWith = "terraform"
  }
}


# Creating Private subnets

resource "aws_subnet" "main3" {
  vpc_id     = "${aws_vpc.3tier.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone="us-east-2a"


  tags = {
    Name      = "Private Subnet1"
    BuildWith = "terraform"
  }
}

resource "aws_subnet" "main4" {
  vpc_id     = "${aws_vpc.3tier.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone="us-east-2c"

  tags = {
    Name      = "Private Subnet2"
    BuildWith = "terraform"
  }
}


#Creating Pubilc route table

resource "aws_route_table" "public_route_table" {
  vpc_id = "${ aws_vpc.3tier.id }"

  tags {
    Name      = "Public Subnet Route Table"
    BuildWith = "terraform"
  }
}


#Creating Private route table

resource "aws_route_table" "private_route_table" {
  vpc_id = "${ aws_vpc.3tier.id }"

  tags {
    Name      = "Private Subnet Route Table"
    BuildWith = "terraform"
  }
}

# associate subnet public to public route table
resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = "${ aws_subnet.main1.id }"
  route_table_id = "${ aws_route_table.public_route_table.id }"
}

resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = "${ aws_subnet.main2.id }"
  route_table_id = "${ aws_route_table.public_route_table.id }"
}

#  associate subnet public to private route table
resource "aws_route_table_association" "private_subnet_association1" {
  subnet_id      = "${ aws_subnet.main3.id }"
  route_table_id = "${ aws_route_table.private_route_table.id }"
}

resource "aws_route_table_association" "private_subnet_association2" {
  subnet_id      = "${ aws_subnet.main4.id }"
  route_table_id = "${ aws_route_table.private_route_table.id }"
}

# create external route to IGW

resource "aws_route" "external_route" {
  route_table_id         = "${ aws_route_table.public_route_table.id }"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${ aws_internet_gateway.gw.id }"
}

# adding an elastic IP
resource "aws_eip" "elastic_ip" {
  vpc        = true
}


# creating the NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = "${ aws_eip.elastic_ip.id }"
  subnet_id     = "${ aws_subnet.main2.id }"
  
}

# adding private route table to nat
resource "aws_route" "private_route" {
  route_table_id         = "${ aws_route_table.private_route_table.id }"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${ aws_nat_gateway.nat.id }"

}
#Security Group for webserver

resource "aws_security_group" "webservers" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.3tier.id}"
  
  ingress {
    # TLS (change to whatever ports you eed)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
}
  ingress {
     from_port = 80
     to_port = 80
     protocol = "tcp"
     cidr_blocks= [ "0.0.0.0/0" ]
}

   ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
}
      
  egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
}
  
  tags = {
          Name      = "Webserver"
          BuildWith = "terraform"
 

  }
}


# Security Group for application servers

resource "aws_security_group" "appservers" {
  name        = "allow_onlyfrontendserver"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.3tier.id}"

  ingress {
    # TLS (change to whatever ports you eed)
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
}
  ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks= [ "0.0.0.0/0" ]
}

  ingress {
     from_port = 3306
     to_port = 3306
     protocol = "tcp"
     cidr_blocks= [ "0.0.0.0/0" ]
}

  ingress {
     from_port = 5439
     to_port = 5439
     protocol = "tcp"
     cidr_blocks= [ "0.0.0.0/0" ]
}
  tags = {
          Name      = "Appserver"
          BuildWith = "terraform"
 

  }
}
