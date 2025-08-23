provider "libvirt" {
  uri = "qemu:///system"
}

# Create a disk for each VM
resource "libvirt_volume" "ubuntu_qcow2" {
  for_each = var.vms

  name   = "${each.key}-ubuntu-disk.qcow2"
  source = var.ubuntu_18_img_url
  format = "qcow2"
  # size   = each.value.disk_size
}

# Create a cloudinit disk for each VM
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.vms

  name           = "${each.key}-commoninit.iso"
  user_data      = templatefile("${path.module}/config/cloud_init.cfg", {
    hostname = each.value.vm_hostname
  })
  network_config = templatefile("${path.module}/config/network_config.yml", {
    ip_address = each.value.ip_address
  })
}

# Create a VM (domain) for each VM configuration
resource "libvirt_domain" "domain_ubuntu" {
  for_each = var.vms

  name   = each.value.vm_hostname
  memory = each.value.memory
  vcpu   = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
    hostname       = each.value.vm_hostname
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu_qcow2[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
