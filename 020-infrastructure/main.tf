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

variable "existing_resource_group_name" {
  default = ""
}

variable "tags" {
  default = ["terraform", "client-vpn"]
}

#
# Create a resource group or reuse an existing one
#
resource "ibm_resource_group" "group" {
  count = var.existing_resource_group_name != "" ? 0 : 1
  name  = "${var.basename}-group"
  tags  = var.tags
}

data "ibm_resource_group" "group" {
  count = var.existing_resource_group_name != "" ? 1 : 0
  name  = var.existing_resource_group_name
}

locals {
  resource_group_id = var.existing_resource_group_name != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
}
