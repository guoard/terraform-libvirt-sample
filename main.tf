provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "pool" {
  name = "default"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/default"
    # permissions = {
    #     owner = "64055" # libvirt-qemu
    #     group = "993" # kvm
    #     mode = "0755"
    # }
  }
}

# Create a disk for each VM.
resource "libvirt_volume" "debian_disk" {
  for_each = var.vms

  name   = "${each.key}.qcow2"
  pool   = libvirt_pool.pool.name
  #https://github.com/dmacvicar/terraform-provider-libvirt/issues/1238
  #target = { format = { type = "qcow2" } }

  create = {
    content = {
      url = "file://${var.debian_12_qcow_path}"
    }
  }
}

# Cloud-init seed ISO.
resource "libvirt_cloudinit_disk" "debian_seed" {
  for_each = var.vms

  name = "${each.key}-cloudinit"

  user_data = templatefile("${path.module}/config/cloud_init.yml", {
    hostname = each.value.hostname
  })
  network_config = templatefile("${path.module}/config/network_config.yml", {
    ip_address = each.value.ip_address
  })

  meta_data = yamlencode({
    instance-id    = each.value.ip_address
    local-hostname = each.value.hostname
  })
}

# Upload the cloud-init ISO into the pool.
resource "libvirt_volume" "debian_seed_volume" {
  for_each = var.vms

  name   = "${each.key}-cloudinit.iso"
  pool   = libvirt_pool.pool.name
  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.debian_seed[each.key].path
    }
  }
}

# Virtual machine definition.
resource "libvirt_domain" "domain_debian" {
  for_each = var.vms

  name   = each.value.hostname
  memory = each.value.memory
  memory_unit   = "MiB"
  vcpu   = each.value.vcpu
  type   = "kvm"

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type = "hvm"
  }

  features = {
    acpi = true
    apic = {}
    pae  = true
  }

  devices = {
    disks = [
      {
        driver = {
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = libvirt_volume.debian_disk[each.key].pool
            volume = libvirt_volume.debian_disk[each.key].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.debian_seed_volume[each.key].pool
            volume = libvirt_volume.debian_seed_volume[each.key].name
          }
        }
        target = {
          dev = "hda"
          bus = "ide"
        }
      },
    ]

    interfaces = [
      {
        type  = "network"
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
        # TODO: wait_for_ip not implemented yet (Phase 2)
        # This will wait during creation until the interface gets an IP
        # wait_for_ip = {
        #   timeout = 300    # seconds, default 300
        #   source  = "any"  # "lease" (DHCP), "agent" (qemu-guest-agent), or "any" (try both)
        # }
      }
    ]

    consoles = [
      {
          target_port = 0
          target_type = "serial"
          type        = "pty"
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }

  running = true
}

data "libvirt_domain_interface_addresses" "debian" {
  for_each = var.vms

  domain = libvirt_domain.domain_debian[each.key].name
  source = "lease" # optional: "lease" (DHCP), "agent" (qemu-guest-agent), or "any"
}
