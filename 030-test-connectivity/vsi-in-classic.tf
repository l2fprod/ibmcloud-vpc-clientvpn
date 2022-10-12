variable "existing_classic_ssh_key" {
  description = "Name of an existing SSH key in classic"
}

data "ibm_compute_ssh_key" "public_key" {
  label = var.existing_classic_ssh_key
}

variable "vsi_in_classic_datacenter" {
  default     = "dal10"
  description = "Datacenter where to create the classic VSI"
}

data "ibm_security_group" "allow_ssh" {
  name = "allow_ssh"
}

resource "ibm_compute_vm_instance" "vsi" {
  hostname             = "${var.basename}-classic-vsi"
  domain               = "example.com"
  os_reference_code    = "UBUNTU_18_64"
  datacenter           = var.vsi_in_classic_datacenter
  network_speed        = 1000
  hourly_billing       = true
  private_network_only = true
  cores                = 1
  memory               = 1024

  ssh_key_ids = [data.ibm_compute_ssh_key.public_key.id]
}

# route traffic from clients to hosts in the classic network
# https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-to-site-overview#integrate-transit-vpn-gateway
resource "ibm_is_vpn_server_route" "route_to_classic" {
  name        = "${var.basename}-to-classic"
  vpn_server  = data.terraform_remote_state.infrastructure.outputs.vpn.id
  action      = "translate"
  destination = ibm_compute_vm_instance.vsi.private_subnet
}

output "vsi_in_classic_ip" {
  value = ibm_compute_vm_instance.vsi.ipv4_address_private
}
