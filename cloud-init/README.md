# Cloud-Init Configurations

Simple cloud-init scripts for bootstrapping Proxmox VMs deployed with Terraform.

## 📁 Available Configurations

| File                     | Purpose                      | Includes                                                  |
| ------------------------ | ---------------------------- | --------------------------------------------------------- |
| `basic-bootstrap.yml`    | Essential server setup       | Users, SSH keys, qemu-agent, basic tools                  |
| `enhanced-bootstrap.yml` | Development/production ready | Everything above + Docker, security hardening, monitoring |

## 🎯 Core Features (Both Configurations)

- ✅ **User Setup**: `admin` and `ansible` users with passwordless sudo
- ✅ **SSH Keys**: Key-based authentication configured
- ✅ **QEMU Guest Agent**: Enabled for Proxmox management
- ✅ **Basic Security**: UFW firewall, SSH hardening
- ✅ **Essential Tools**: vim, git, htop, curl, wget

## 🚀 Terraform Usage

### Basic Setup

```hcl
resource "proxmox_vm_qemu" "server" {
  name        = "my-server"
  target_node = "pve01"
  clone       = "9000"  # Your cloud template ID
  full_clone  = true

  cores   = 2
  memory  = 2048

  # Network configuration
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init configuration
  cloudinit_cdrom_storage = "local-lvm"

  # Use basic bootstrap
  cicustom = "user=local:snippets/basic-bootstrap.yml"

  # Or reference from your repo/storage
  # cicustom = "user=pve-nas:snippets/basic-bootstrap.yml"

  ciuser      = "admin"
  cipassword  = "changeme123"  # Optional, SSH keys are primary
  ipconfig0   = "ip=dhcp"
  nameserver  = "8.8.8.8"
  sshkeys     = file("~/.ssh/id_rsa.pub")
}
```

### Enhanced Setup

```hcl
resource "proxmox_vm_qemu" "dev_server" {
  name        = "dev-server"
  target_node = "pve01"
  clone       = "9000"
  full_clone  = true

  cores   = 4
  memory  = 4096

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cloudinit_cdrom_storage = "local-lvm"
  cicustom = "user=local:snippets/enhanced-bootstrap.yml"

  ciuser     = "admin"
  ipconfig0  = "ip=dhcp"
  nameserver = "8.8.8.8"
  sshkeys    = file("~/.ssh/id_rsa.pub")
}
```

## 📋 Setup Instructions

### 1. Install Cloud-Init Files

```bash
# Copy to Proxmox snippets directory
scp *.yml root@pve01:/var/lib/vz/snippets/

# Or for shared storage
scp *.yml root@pve01:/mnt/pve/pve-nas/snippets/

# Set permissions
ssh root@pve01 'chmod 644 /var/lib/vz/snippets/*.yml'
```

### 2. Update SSH Keys

Edit the YAML files and replace the placeholder SSH keys:

```yaml
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... # Replace with your actual SSH public key
```

### 3. Customize Users/Settings

Modify the YAML files to match your environment:

- Change usernames if needed
- Adjust timezone (`America/New_York`)
- Customize package lists
- Modify firewall rules

## 🔧 What Gets Configured

### Basic Bootstrap

- **Users**: `admin`, `ansible` (both with passwordless sudo)
- **SSH**: Key-based authentication enabled
- **Tools**: Essential system utilities
- **Services**: qemu-guest-agent, basic firewall
- **Management**: Simple status script

### Enhanced Bootstrap

- **Everything from basic** +
- **Docker**: Container platform ready
- **Additional Users**: `monitor` user with limited sudo
- **Security**: fail2ban, enhanced firewall rules
- **Development Tools**: python3, node.js, docker-compose
- **Management Scripts**: Enhanced monitoring and Docker helpers

## 🎯 Post-Deployment

### Access Your Server

```bash
# SSH with your key
ssh admin@<server-ip>

# Check status
server-status

# For enhanced setup
docker-helper status
```

### Verify Setup

```bash
# Check cloud-init completed successfully
sudo cloud-init status

# Verify users can sudo without password
sudo whoami

# Test qemu-guest-agent
# (From Proxmox host): qm guest cmd <vmid> network-get-interfaces
```

## 🔐 Security Notes

### Before Production Use

1. **Change default passwords** if using cipassword in Terraform
2. **Review firewall rules** in the cloud-init files
3. **Add your SSH keys** to replace the placeholders
4. **Customize user accounts** as needed for your environment

### SSH Key Setup

```bash
# Generate SSH key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Get your public key for the YAML files
cat ~/.ssh/id_rsa.pub
```

## 🚀 Quick Start

1. **Create your templates** using the main script
2. **Copy cloud-init files** to Proxmox snippets storage
3. **Update SSH keys** in the YAML files
4. **Deploy with Terraform** using the examples above
5. **SSH to your server** and verify everything works

Simple, focused, and ready for Terraform automation! 🎉
