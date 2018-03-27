###################################################################################################################
##  Variables
###################################################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {
  default = "KopsUser"
}

###################################################################################################################
##  Providers
###################################################################################################################

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "ap-south-1"
}

###################################################################################################################
##  Resources
###################################################################################################################

resource "aws_instance" "nginx" {

    ami = "ami-7c87d913"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"

    connection {
      user = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }

    provisioner "remote-exec" {
      inline = [
      "sudo yum install -y nginx",
      "sudo service nginx start"
      ]
    }
}

###################################################################################################################
##  Output
###################################################################################################################

output "aws_instance_public_dns" {
    value = "${aws_instance.nginx.public_dns}"
}