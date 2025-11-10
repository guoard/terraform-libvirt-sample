output "vm_interfaces" {
  description = "All network interfaces with their IP addresses per VM"
  value = {
    for k, v in data.libvirt_domain_interface_addresses.debian :
    k => v.interfaces
  }
}

output "vm_ip" {
  description = "First IP address of each VM"
  value = {
    for k, v in data.libvirt_domain_interface_addresses.debian :
    k => (
      length(v.interfaces) > 0 && length(v.interfaces[0].addrs) > 0 ?
      v.interfaces[0].addrs[0].addr :
      "No IP address found"
    )
  }
}

output "vm_all_ips" {
  description = "All IP addresses for each VM"
  value = {
    for k, v in data.libvirt_domain_interface_addresses.debian :
    k => flatten([
      for iface in v.interfaces : [
        for addr in iface.addrs : addr.addr
      ]
    ])
  }
}
