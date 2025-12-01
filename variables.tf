variable "debian_12_qcow_path" {
  default = "/home/ali/w/terraform-libvirt-sample/debian-12-genericcloud-amd64-daily.qcow2"
}

variable "vms" {
  description = "Map of VM configurations"
  type = map(object({
    hostname   = string
    memory     = number
    vcpu       = number
    ip_address = string
  }))
  default = {
    "vm1" = {
      hostname   = "vm1"
      memory     = 4096
      vcpu       = 2
      ip_address = "192.168.122.101"
    },
    "vm2" = {
      hostname = "vm2"
      memory      = 4096
      vcpu        = 2
      ip_address  = "192.168.122.102"
    },
    "vm3" = {
      hostname = "vm3"
      memory      = 4096
      vcpu        = 2
      ip_address  = "192.168.122.103"
    },
  }
}
