variable "vpc_cidr" {
  default = "10.10.10.0/24"
}

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.basename}-vpc"
  resource_group            = local.resource_group_id
  address_prefix_management = "manual"
  tags                      = concat(var.tags, ["vpc"])
}

resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  name = "${var.basename}-zone-1"
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.vpc.id
  cidr = var.vpc_cidr
}

resource "ibm_is_network_acl" "network_acl" {
  name           = "${var.basename}-acl"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id

  rules {
    name        = "egress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "ingress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.basename}-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.region}-1"
  resource_group  = local.resource_group_id
  ipv4_cidr_block = ibm_is_vpc_address_prefix.subnet_prefix.cidr
  network_acl     = ibm_is_network_acl.network_acl.id
  tags            = concat(var.tags, ["vpc"])
}

resource "ibm_is_security_group" "group" {
  name           = "${var.basename}-sg"
  resource_group = local.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  tags           = concat(var.tags, ["vpc"])
}

resource "ibm_is_security_group_rule" "inbound_ssh" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "inbound_ping" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  icmp {
    type = 8
    code = 0
  }
}

resource "ibm_is_security_group_rule" "outbound_http" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  tcp {
    port_max = 80
    port_min = 80
  }
}

resource "ibm_is_security_group_rule" "outbound_ssh" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "outbound_ping" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  icmp {
    type = 8
    code = 0
  }
}

resource "ibm_is_security_group_rule" "outbound_https" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  tcp {
    port_max = 443
    port_min = 443
  }
}

resource "ibm_is_security_group_rule" "outbound_dns" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  udp {
    port_max = 53
    port_min = 53
  }
}

resource "ibm_is_security_group_rule" "outbound_cse" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "166.9.0.0/16"
}

resource "ibm_is_security_group_rule" "outbound_private" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "161.26.0.0/16"
}

output "vpc" {
  value = ibm_is_vpc.vpc
}

output "subnet" {
  value = ibm_is_subnet.subnet
}

output "security_group" {
  value = ibm_is_security_group.group
}