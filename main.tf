terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
  }
}

provider "aws" {
  region     = "us-west-2"
}

# https://github.com/aws-ia/terraform-aws-vpc
module "primary_vpc" {
  source = "./terraform-aws-vpc"
  name       = "multi-az-vpc"
  cidr_block = "172.16.0.0/20"
  az_count   = 3
  subnets = {
    public = {
      cidrs                     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
      nat_gateway_configuration = "all_azs" # options: "single_az", "none"
    }
    private = {
      name_prefix             = "private_workload"
      connect_to_public_natgw = true
      cidrs                   = ["172.16.4.0/22", "172.16.8.0/22", "172.16.12.0/22"]
    }
  }
}

# To add in the secondary cidr
module "secondary_vpc" {
  source = "./terraform-aws-vpc"
  depends_on = [module.primary_vpc]
  name       = "secondary-cidr"
  cidr_block = "10.200.0.0/26" # pretend this is a private IP cidr range
  az_count   = 3
  create_vpc = false

#   vpc_secondary_cidr       = true
  vpc_id                   = module.primary_vpc.vpc_attributes.id
#   vpc_secondary_cidr_natgw = module.primary_vpc.natgw_id_per_az

  subnets = {
    private = {
      name_prefix             = "private_internal"
      cidrs                   = ["10.200.0.0/28", "10.200.0.16/28", "10.200.0.32/28"]
    #   netmask = 28
      connect_to_public_natgw = false #true
    }
  }
}

