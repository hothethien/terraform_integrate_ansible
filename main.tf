provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  cloud {
    organization = "job_16072022"

    workspaces {
      name = "terraform_integrate_ansible"
    }
  }
}   

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["ap-southeast-1a"]

  public_subnets  = ["10.0.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ssh-service"
  description = "Security group for sshd with port publicly open"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "thienht"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCIGs8R6P2+0QQ1JHAZ8nFeRCvG1fqUe7TZJpFNpYFc7oEqL8uQJTr2E/YKp+z6aVMiz81bef3rElgVjAllYPXQJFiBiWe+txlh/IsrQPN1H/S90CyokjyxG7ddHNCJX7sWtpsnUZqcS4VU4wlBd2z5WFtKdC7Am89R8VY5GKOBg3RKIElv1WYMjyWq7gbsemQuf2KARA38Huq0YQ8x2R7WatdyhFJF+kbVKfAdr6pE5NnP87IFC+tszqCnSIk5ZSSk6kkUoAeZCCPigxIFPTwQ78dawc50Cv0eX/kH0zQWfYdk9GS/LT6Maqck2R6nmEsLU/5oM6Pwzl/vENrkWg4x rsa-key-20211110"
}

# module "ec2_instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
resource "aws_instance" "centos" {
  # name                   = "centos"
  ami                    = "ami-051f0947e420652a9"
  instance_type          = "t2.micro"
  key_name               = "thienht"
  vpc_security_group_ids = [module.sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd.x86_64",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]

  connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("private.pem")
      host        = self.public_ip
    } 
  }
}

