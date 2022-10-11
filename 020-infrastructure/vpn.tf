data "terraform_remote_state" "certificates" {
  backend = "local"

  config = {
    path = "../010-certificates/terraform.tfstate"
  }
}

variable "vpn_client_ip_pool" {
  default = "192.168.0.0/16"
}

resource "ibm_is_vpn_server" "vpn" {
  certificate_crn = data.terraform_remote_state.certificates.outputs.server_cert_crn
  client_authentication {
    method        = "certificate"
    client_ca_crn = data.terraform_remote_state.certificates.outputs.client_cert_crn
  }
  client_ip_pool         = var.vpn_client_ip_pool
  client_idle_timeout    = 2800
  enable_split_tunneling = true
  name                   = "${var.basename}-vpn-server"
  port                   = 443
  protocol               = "udp"
  subnets = [
    ibm_is_subnet.subnet.id
  ]
  security_groups = [
    ibm_is_security_group.vpn.id
  ]
  resource_group = local.resource_group_id
}

resource "ibm_is_security_group" "vpn" {
  resource_group = local.resource_group_id
  name           = "${var.basename}-vpn-group"
  vpc            = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "vpn_inbound" {
  group     = ibm_is_security_group.vpn.id
  direction = "inbound"
  udp {
    port_min = 443
    port_max = 443
  }
}

# allow clients to use SSH to connect to hosts in the cloud
resource "ibm_is_security_group_rule" "vpn_ssh_outbound" {
  group     = ibm_is_security_group.vpn.id
  direction = "outbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# allow clients to use SSH to ping
resource "ibm_is_security_group_rule" "vpn_icmp_outbound" {
  group     = ibm_is_security_group.vpn.id
  direction = "outbound"
  icmp {
    type = 8
    code = 0
  }
}

# allow clients to reach cloud service endpoints
resource "ibm_is_security_group_rule" "vpn_cse_outbound" {
  group     = ibm_is_security_group.vpn.id
  direction = "outbound"
  remote    = "166.9.0.0/16"
}

data "ibm_is_vpn_server_client_configuration" "config" {
  vpn_server = ibm_is_vpn_server.vpn.id
  file_path  = "../config/client.ovpn"
}

resource "local_file" "fullconfig" {
  content=<<EOT
${data.ibm_is_vpn_server_client_configuration.config.vpn_server_client_configuration}

<cert>
${data.terraform_remote_state.certificates.outputs.client_cert}
</cert>

<key>
${data.terraform_remote_state.certificates.outputs.client_key}
</key>
EOT
  filename = "../config/client-full.ovpn"
}