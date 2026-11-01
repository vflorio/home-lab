# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "dns" {
    
    # VM General Settings
    target_node = "homelab"
    vmid = "1010"
    name = "dns"
    desc = "DNS Server"

    # VM Advanced General Settings
    onboot = true 

    # VM OS Settings
    clone = "ubuntu-server-noble"

    # VM System Settings
    agent = 1
    boot = "order=virtio0;ide2"

    # VM CPU Settings
    cores = 2
    sockets = 1
    cpu_type = "host"
    
    # VM Memory Settings
    memory = 2048

    # VM Network Settings
    network {
        id = 0
        bridge = "vmbr0"
        model  = "virtio"
    }

    # VM Disk Settings
    disks {
        ide {
            ide2 {
                cloudinit {
                    storage = "local-lvm"
                }
            }
        }
        virtio {
            virtio0 {
                disk {
                    format = "raw"
                    storage = "local-lvm"
                    size = 20
                }
            }
        }
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    # IP Address and Gateway
    ipconfig0 = "ip=192.168.1.150/24,gw=192.168.1.254"

    # Default User
    ciuser = "vflorio"
    
    # Add your SSH KEYs - HomeLab Device Keys
    sshkeys = <<EOF
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9KEOXdWXLzje6wV3UdyDhGIJAYiplHp9T3CBqNaQSi silicon-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPe+jlx13luhQaGUaKhBxctrGqnMPojuFsLY6ueaU4UE carbon-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDr8H7YMo8vYEsLGG7Fajxrc/hSm8dmJi5fD0gPhyk4 nitrogen-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIk+9gU78p2YjX6qnJ05pbwV72lA2BhhamOCp41WjUIu boron-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEjryCfRPjPiIxTXFWiBQwtp0v2t2IWJ7/+irrq8Y7yj phosphorus-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGrdFzkXL28Ed5qAolx0oseX78/YH6rIViPYzdLYiTPP sulfur-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfM/qlE7yoXHOGPK4sNhl/QdL9Pr97+xU4BBEumxmms chlorine-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBh2O0ySg7/uzKWRs65IZDp9Gi8oFS3zsNtspYVd4dsa argon-homelab-2025-09-14
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpehUd+r1Z0Cy0fFZCrQ5wJfMZ08Apyi7ZMoNMFtrgM neon-homelab-2025-09-14
    EOF
}
