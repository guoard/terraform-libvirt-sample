variable "ubuntu_18_img_url" {
  description = "Path or URL to the Ubuntu image"
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "disk_size" {
  description = "Disk size in bytes for each VM"
  type        = number
  default     = 10737418240
}

variable "vms" {
  description = "Map of VM configurations"
  type = map(object({
    vm_hostname = string
    memory      = number
    vcpu        = number
  }))
  default = {
    "vm1" = {
      vm_hostname = "vm1"
      memory      = 2048
      vcpu        = 2
    },
    "vm2" = {
      vm_hostname = "vm2"
      memory      = 2048
      vcpu        = 2
    },
    "vm3" = {
      vm_hostname = "vm3"
      memory      = 2048
      vcpu        = 2
    },
    "vm4" = {
      vm_hostname = "vm4"
      memory      = 2048
      vcpu        = 2
    }
  }
}
