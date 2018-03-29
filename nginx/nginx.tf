###################################################################################################################
##  Variables
###################################################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "private_key_path" {}
variable "key_name" {
  default = "DevOpsUser"
}
variable "cidr_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.1.0/24"
}
variable "subnet2_address_space" {
  default = "10.1.2.0/24"
}

###################################################################################################################
##  Providers
###################################################################################################################

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

###################################################################################################################
##  Data
###################################################################################################################

data "aws_availability_zones" "available" {}

###################################################################################################################
##  Resources
###################################################################################################################

## Networking ##
resource "aws_vpc" "vpc" {
    cidr_block = "${var.cidr_address_space}"
    enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "subnet1" {
    cidr_block = "${var.subnet1_address_space}"
    vpc_id =  "${aws_vpc.vpc.id}"
    map_public_ip_on_launch = "true"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "subnet2" {
    cidr_block = "${var.subnet2_address_space}"
    vpc_id =  "${aws_vpc.vpc.id}"
    map_public_ip_on_launch = "true"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

## Routing ##
resource "aws_route_table" "rt" {
    vpc_id = "${aws_vpc.vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
}

resource "aws_route_table_association" "rt-subnet1" {
    subnet_id = "${aws_subnet.subnet1.id}"
    route_table_id = "${aws_route_table.rt.id}"
}


resource "aws_route_table_association" "rt-subnet2" {
    subnet_id = "${aws_subnet.subnet2.id}"
    route_table_id = "${aws_route_table.rt.id}"
}

## Security Group ##
resource "aws_security_group" "nginx-sg" {

    name = "nginx-sg"
    vpc_id = "${aws_vpc.vpc.id}"

    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["202.142.121.177/32"]
    }

    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "elb-sg" {

    name = "elb-sg"
    vpc_id = "${aws_vpc.vpc.id}"

    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

## Load Balancer ##
resource "aws_elb" "nginx-elb" {
    name = "nginx-elb"

    subnets = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
    security_groups = ["${aws_security_group.elb-sg.id}"]
    instances = ["${aws_instance.nginx1.id}", "${aws_instance.nginx2.id}"]

    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
}

## Instances ##
resource "aws_instance" "nginx1" {

    ami = "ami-7c87d913"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.subnet1.id}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
    key_name = "${var.key_name}"

    connection {
      user = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }

    provisioner "remote-exec" {
      inline = [
      "sudo yum install -y nginx",
      "sudo service nginx enable",
      "sudo service nginx start"
      ]
    }
}

resource "aws_instance" "nginx2" {

    ami = "ami-7c87d913"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.subnet2.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
    key_name = "${var.key_name}"

    connection {
      user = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }

    provisioner "remote-exec" {
      inline = [
      "sudo yum install -y nginx",
      "sudo service nginx enable",
      "sudo service nginx start"
      ]
    }
}

###################################################################################################################
##  Output
###################################################################################################################

output "aws_instance_public_dns" {
    value = "${aws_elb.nginx-elb.dns_name}"
}