terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.45"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 1.17"
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

provider "restapi" {
  uri                  = "https://${var.existing_secrets_manager_id}.${var.region}.secrets-manager.appdomain.cloud"
  debug                = true
  write_returns_object = true
  headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}

resource "null_resource" "resource_change" {
  triggers = {
    a_change = jsonencode(module.pki)
  }
}

resource "restapi_object" "secret_group" {
  path = "/api/v1/secret_groups"

  data = jsonencode({
    metadata = {
      collection_type  = "application/vnd.ibm.secrets-manager.secret.group+json"
      collection_total = 1
    }
    resources = [
      {
        name        = "${var.basename}-group"
        description = "Created by terraform as part of the client VPN example."
      }
    ]
  })
  id_attribute = "resources/0/id"
  debug        = true
}

resource "restapi_object" "server_cert" {
  path = "/api/v1/secrets/imported_cert"

  data = jsonencode({
    metadata = {
      collection_type  = "application/vnd.ibm.secrets-manager.secret+json"
      collection_total = 1
    }
    resources = [
      {
        name            = "${var.basename}-server-cert"
        description     = "Server certificate created by terraform as part of the client VPN example."
        secret_group_id = restapi_object.secret_group.id
        certificate     = module.pki.certificates["server"].cert.cert_pem
        private_key     = module.pki.certificates["server"].private_key.private_key_pem
        intermediate    = module.pki.ca.cert.cert_pem
      }
    ]
  })
  id_attribute = "resources/0/id"
  debug        = true

  # force secrets to be recreate if anything changes in the certificates
  lifecycle {
    replace_triggered_by = [
      null_resource.resource_change.triggers
    ]
  }
}

resource "restapi_object" "client_cert" {
  path = "/api/v1/secrets/imported_cert"

  data = jsonencode({
    metadata = {
      collection_type  = "application/vnd.ibm.secrets-manager.secret+json"
      collection_total = 1
    }
    resources = [
      {
        name            = "${var.basename}-client-cert"
        description     = "Client certificate created by terraform as part of the client VPN example."
        secret_group_id = restapi_object.secret_group.id
        certificate     = module.pki.certificates["client"].cert.cert_pem
        intermediate    = module.pki.ca.cert.cert_pem
      }
    ]
  })
  id_attribute = "resources/0/id"
  debug        = true

  # force secrets to be recreate if anything changes in the certificates
  lifecycle {
    replace_triggered_by = [
      null_resource.resource_change.triggers
    ]
  }
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
    value = restapi_object.secret_group.id
  }
}

output "server_cert_crn" {
  value = jsondecode(restapi_object.server_cert.api_response).resources.0.crn
}

output "client_cert_crn" {
  value = jsondecode(restapi_object.client_cert.api_response).resources.0.crn
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
