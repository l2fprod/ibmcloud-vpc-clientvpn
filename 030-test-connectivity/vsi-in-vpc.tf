variable "vsi_in_vpc_image" {
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-2"
  description = "Image name for the VSI in VPC"
}

data "ibm_is_image" "image" {
  name = var.vsi_in_vpc_image
}

variable "ssh_key_name" {
  description = "Name of an existing SSH key in VPC"
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

resource "ibm_is_instance" "vsi" {
  name           = "${var.basename}-vsi"
  vpc            = data.terraform_remote_state.infrastructure.outputs.vpc.id
  zone           = "${var.region}-1"
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.image.id
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  resource_group = data.terraform_remote_state.infrastructure.outputs.resource_group_id

  primary_network_interface {
    subnet = data.terraform_remote_state.infrastructure.outputs.subnet.id
    security_groups = [
      data.terraform_remote_state.infrastructure.outputs.security_group.id
    ]
  }

  boot_volume {
    name = "${var.basename}-vsi-boot"
  }

  tags = concat(var.tags, ["vpc"])
}

# route traffic from clients to hosts in the VPC
resource "ibm_is_vpn_server_route" "route_to_vpc" {
  vpn_server  = data.terraform_remote_state.infrastructure.outputs.vpn.id
  action      = "deliver"
  destination = data.terraform_remote_state.infrastructure.outputs.subnet.ipv4_cidr_block
}

output "vsi_in_vpc_ip" {
  value = ibm_is_instance.vsi.primary_network_interface.0.primary_ip.0.address
}
