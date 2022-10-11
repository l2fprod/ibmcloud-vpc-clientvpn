terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.45"
    }
  }
}

provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
  iaas_classic_username = var.iaas_classic_username
  iaas_classic_api_key = var.iaas_classic_api_key
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key to create resources"
}

variable "iaas_classic_username" {
  description = "The IBM Cloud Classic Infrastructure (SoftLayer) user name"
}

variable "iaas_classic_api_key" {
  description = "The IBM Cloud Classic Infrastructure API key"
}

variable "region" {
  default     = "us-south"
  description = "Region where to find and create resources"
}

variable "basename" {
  default     = "client-vpn"
  description = "Prefix for all resources created by the template"
}

variable "tags" {
  default = ["terraform", "client-vpn"]
}

data "terraform_remote_state" "infrastructure" {
  backend = "local"

  config = {
    path = "../020-infrastructure/terraform.tfstate"
  }
}
