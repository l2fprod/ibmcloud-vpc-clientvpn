resource "ibm_tg_gateway" "tg" {
  name           = "${var.basename}-tg"
  location       = var.region
  global         = true
  resource_group = local.resource_group_id
}

resource "ibm_tg_connection" "vpc" {
  gateway      = ibm_tg_gateway.tg.id
  network_type = "vpc"
  name         = "${var.basename}-vpc"
  network_id   = ibm_is_vpc.vpc.crn
}

resource "ibm_tg_connection" "classic" {
  gateway      = ibm_tg_gateway.tg.id
  network_type = "classic"
  name         = "${var.basename}-classic"
}