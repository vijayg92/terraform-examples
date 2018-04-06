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