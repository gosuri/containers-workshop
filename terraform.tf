variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret key"
}

variable "key_name" {
  description = "AWS instance key pair name"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "us-east-1"
}

resource "aws_security_group" "allow_all" {
  name = "ap-workshop-allow-all"
  description = "Airpair workshop demo SG to allow all inbound traffic"
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "ap-workshop-allow-all" }
}

resource "aws_instance"  "provisioner" {
  tags = { Name = "airpair-workshop-provisioner" }
  ami = "ami-8caa1ce4"
  instance_type = "m3.medium"
  security_groups = ["${aws_security_group.allow_all.name}"]
  key_name = "${var.key_name}"
}
