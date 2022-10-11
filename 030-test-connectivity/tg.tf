resource "ibm_tg_gateway" "tg" {
  name           = "${var.basename}-tg"
  location       = var.region
  global         = true
  resource_group = data.terraform_remote_state.infrastructure.outputs.resource_group_id
}

resource "ibm_tg_connection" "vpc" {
  gateway      = ibm_tg_gateway.tg.id
  network_type = "vpc"
  name         = "${var.basename}-vpc"
  network_id   = data.terraform_remote_state.infrastructure.outputs.vpc.crn
}

resource "ibm_tg_connection" "classic" {
  gateway      = ibm_tg_gateway.tg.id
  network_type = "classic"
  name         = "${var.basename}-classic"
}