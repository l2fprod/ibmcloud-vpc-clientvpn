terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.51"
    }
  }
}

provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key to create resources"
}

variable "region" {
  default     = "us-south"
  description = "Region where to find and create resources"
}

variable "existing_secrets_manager_id" {
  description = "ID of an existing Secrets Manager instance located in the same region"
}

data "ibm_iam_auth_token" "tokendata" {}
data "ibm_iam_account_settings" "iam_account_settings" {}

resource "ibm_sm_secret_group" "secret_group" {
  instance_id = var.existing_secrets_manager_id
  name        = "${var.basename}-group"
  description = "Created by terraform as part of the client VPN example."
}

resource "ibm_sm_imported_certificate" "server_cert" {
  instance_id     = var.existing_secrets_manager_id
  name            = "${var.basename}-server-cert"
  description     = "Server certificate created by terraform as part of the client VPN example."
  secret_group_id = ibm_sm_secret_group.secret_group.secret_group_id
  certificate     = module.pki.certificates["server"].cert.cert_pem
  private_key     = module.pki.certificates["server"].private_key.private_key_pem
  intermediate    = module.pki.ca.cert.cert_pem
}

resource "ibm_sm_imported_certificate" "client_cert" {
  instance_id     = var.existing_secrets_manager_id
  name            = "${var.basename}-client-cert"
  description     = "Client certificate created by terraform as part of the client VPN example."
  secret_group_id = ibm_sm_secret_group.secret_group.secret_group_id
  certificate     = module.pki.certificates["client"].cert.cert_pem
  intermediate    = module.pki.ca.cert.cert_pem
}

resource "ibm_iam_authorization_policy" "secret_group_to_vpn" {
  subject_attributes {
    name  = "accountId"
    value = data.ibm_iam_account_settings.iam_account_settings.account_id
  }

  subject_attributes {
    name  = "serviceName"
    value = "is"
  }

  subject_attributes {
    name  = "resourceType"
    value = "vpn-server"
  }

  roles = ["SecretsReader"]

  resource_attributes {
    name  = "accountId"
    value = data.ibm_iam_account_settings.iam_account_settings.account_id
  }

  resource_attributes {
    name  = "serviceName"
    value = "secrets-manager"
  }

  resource_attributes {
    name  = "resourceType"
    value = "secret-group"
  }

  resource_attributes {
    name  = "resource"
    value = ibm_sm_secret_group.secret_group.secret_group_id
  }
}

output "server_cert_crn" {
  value = ibm_sm_imported_certificate.server_cert.crn
}

output "client_cert_crn" {
  value = ibm_sm_imported_certificate.client_cert.crn
}

output "client_cert" {
  value     = module.pki.certificates["client"].cert.cert_pem
  sensitive = true
}

output "client_key" {
  value     = module.pki.certificates["client"].private_key.private_key_pem
  sensitive = true
}

resource "local_file" "ca_cert" {
  content  = module.pki.ca.cert.cert_pem
  filename = "../config/ca.crt"
}

resource "local_file" "server_cert" {
  content  = module.pki.certificates["server"].cert.cert_pem
  filename = "../config/server.crt"
}

resource "local_file" "server_key" {
  content  = module.pki.certificates["server"].private_key.private_key_pem
  filename = "../config/server.key"
}

resource "local_file" "client_cert" {
  content  = module.pki.certificates["client"].cert.cert_pem
  filename = "../config/client.crt"
}

resource "local_file" "client_key" {
  content  = module.pki.certificates["client"].private_key.private_key_pem
  filename = "../config/client.key"
}
