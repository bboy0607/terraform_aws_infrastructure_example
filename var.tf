variable "ami" {
  description = "the ami you want to launch servers"
  default = "ami-055147723b7bca09a"
}

variable "app" {
  description = "the market you want to launch servers"
  default = "alpha"
}

variable "domain" {
  description = "the environment you want to launch servers"
  default = "test"
}

variable "subnet" {
  description = "the subnet you want to launch servers"
  default = "subnet-08064bb93fcd12886"
}

data "aws_subnet" "selected" {
  id = "${var.subnet}"
}