//Defined in tfvars
variable cidr {}

//Create a VPC
resource "aws_vpc" "webVPC" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "webVPC"
  }
}


//Internet Gateway
resource "aws_internet_gateway" "webIG" {
  vpc_id = "${aws_vpc.webVPC.id}"
  tags {
    Name = "webIG"
  }
}


//Public subnet 1
resource "aws_subnet" "webPublicSubnet1" {
  vpc_id = "${aws_vpc.webVPC.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags {
    Name = "webPublicSubnet1"
  }
}

//Public subnet 2
resource "aws_subnet" "webPublicSubnet2" {
  vpc_id = "${aws_vpc.webVPC.id}"
  cidr_block = "10.0.0.0/24"
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


//Attach route table to subnet
resource "aws_route_table_association" "webRTAssoc" {
  subnet_id = "${aws_subnet.webPublicSubnet1.id}"
  route_table_id = "${aws_route_table.webRouteTable.id}"
}


//Create a security group
resource "aws_security_group" "web_public_sg" {
    name = "web_public_sg"
    description = "Web public access security group"
    vpc_id = "${aws_vpc.webVPC.id}"

   ingress {
       from_port = 22
       to_port = 22
       protocol = "tcp"
       cidr_blocks = [
          "0.0.0.0/0"]
   }

   ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [
          "0.0.0.0/0"]
   }

   ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = [
          "0.0.0.0/0"]
    }

//Fetching cidr from tfvars file
   ingress {
      from_port = 0
      to_port = 0
      protocol = "tcp"
      cidr_blocks = [
         "${var.cidr}"]
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




