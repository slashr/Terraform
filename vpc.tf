//Create a VPC
resource "aws_vpc" "webVPC" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "webVPC"
  }
}


//Creates an Internet Gateway
resource "aws_internet_gateway" "webIG" {
  vpc_id = "${aws_vpc.webVPC.id}"
  tags {
    Name = "webIG"
  }
}


//Creates Public subnet 1
resource "aws_subnet" "webPublicSubnet1" {
  vpc_id = "${aws_vpc.webVPC.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags {
    Name = "webPublicSubnet1"
  }
}

//Creates Public subnet 2
resource "aws_subnet" "webPublicSubnet2" {
  vpc_id = "${aws_vpc.webVPC.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags {
    Name = "webPublicSubnet2"
  }
}

//Route Table for subnet
resource "aws_route_table" "webRouteTable" {
  vpc_id = "${aws_vpc.webVPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.webIG.id}"
  }
}


//Attach route table to subnet 1
resource "aws_route_table_association" "webRTAssoc1" {
  subnet_id = "${aws_subnet.webPublicSubnet1.id}"
  route_table_id = "${aws_route_table.webRouteTable.id}"
}

//Attach route table to subnet 2
resource "aws_route_table_association" "webRTAssoc2" {
  subnet_id = "${aws_subnet.webPublicSubnet2.id}"
  route_table_id = "${aws_route_table.webRouteTable.id}"
}


//Create a security group
resource "aws_security_group" "web_public_sg" {
    name = "web_public_sg"
    description = "Web public access security group"
    vpc_id = "${aws_vpc.webVPC.id}"


   ingress {
      from_port = "0"
      to_port = "0"
      protocol = "-1"
      cidr_blocks = [
         "109.109.206.112/28", "217.5.240.176/29"]
   }

   ingress {
      from_port = "80"
      to_port = "80"
      protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"]
   }

    egress {
        # allow all traffic to private SN
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [
            "0.0.0.0/0"]
    }
}

