source "proxmox-iso" "ubuntu-server-resolute" {
  proxmox_url               = "${var.proxmox_api_url}"
  username                  = "${var.proxmox_api_token_id}"
  token                     = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify  = true

  node                      = "homelab"
  vm_id                     = "106"
  vm_name                   = "ubuntu-server-resolute"
  template_description      = "Ubuntu 26.04.1 LTS"

  iso_file                  = "proxmox-data:iso/ubuntu-26.04.1-live-server-amd64.iso"
  iso_storage_pool          = "proxmox-data"
  unmount_iso               = true
  qemu_agent                = true

  scsi_controller           = "virtio-scsi-pci"

  cores                     = "2"
  sockets                   = "1"
  memory                    = "2048"

  cloud_init                = true
  cloud_init_storage_pool   = "local-lvm"

  vga {
    type                    = "virtio"
  }

  disks {
    disk_size               = "20G"
    format                  = "raw"
    storage_pool            = "local-lvm"
    type                    = "virtio"
  }

  network_adapters {
    model                   = "virtio"
    bridge                  = "vmbr0"
    firewall                = "false"
  }

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://192.168.1.2:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  
  boot                      = "c"
  boot_wait                 = "6s"
  communicator              = "ssh"

  http_directory            = "ubuntu-server-resolute/http"
# http_bind_address         = "192.168.1.2" # questo causa problemi con WSL
  http_port_min             = 8030
  http_port_max             = 8030

  ssh_username              = "${var.ssh_username}"
  ssh_password              = "${var.ssh_password}"

  # Raise the timeout, when installation takes longer
  ssh_timeout               = "30m"
  ssh_pty                   = true
  ssh_handshake_attempts    = 15
}

build {

  name    = "ubuntu-server-resolute"
  sources = [
      "proxmox-iso.ubuntu-server-resolute"
  ]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
      inline = [
          "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
          "sudo rm /etc/ssh/ssh_host_*",
          "sudo truncate -s 0 /etc/machine-id",
          "sudo apt -y autoremove --purge",
          "sudo apt -y clean",
          "sudo apt -y autoclean",
          "sudo cloud-init clean",
          "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
          "sudo rm -f /etc/netplan/00-installer-config.yaml /etc/netplan/50-cloud-init.yaml",
          "sudo sync"
      ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "ubuntu-server-resolute/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}
