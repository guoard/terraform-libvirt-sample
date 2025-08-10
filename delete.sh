#!/bin/bash

for vm in $(sudo virsh list --all --name); do
  sudo virsh destroy "$vm" 2>/dev/null
  sudo virsh undefine "$vm" --remove-all-storage 2>/dev/null
done
