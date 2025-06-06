# Proxmox Cloud Template Creation Script

A comprehensive script for creating cloud-init templates in Proxmox VE clusters with **optimized VGA console access**. This script automates the entire process of downloading cloud images, creating VMs, importing disks, configuring cloud-init, and converting to templates.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Storage Strategy](#storage-strategy)
- [Console Configuration](#console-configuration)
- [Basic Usage](#basic-usage)
- [Template Creation Examples](#template-creation-examples)
- [VM Cloning and Configuration](#vm-cloning-and-configuration)
- [SSH Key Setup](#ssh-key-setup)
- [Cloud-Init Configuration](#cloud-init-configuration)
- [Cluster Operations](#cluster-operations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This script creates cloud-init ready templates **optimized for Proxmox VE console access** that can be:

- Stored on shared storage for cluster-wide access
- Cloned to local storage for optimal VM performance
- Configured with SSH keys for secure access
- Customized with cloud-init for automated provisioning
- **Accessed via interactive VGA console for troubleshooting**

### Key Features

- ✅ Supports Debian, Ubuntu, Rocky Linux, and other cloud images
- ✅ **VGA console configuration for optimal Proxmox console access**
- ✅ **Serial port enabled for guest agent functionality**
- ✅ Cluster-aware storage detection (shared vs local)
- ✅ Automated disk import and cloud-init configuration
- ✅ SSH key integration
- ✅ Template ID validation (9000-9999 range recommended)
- ✅ Comprehensive error handling and logging

## Prerequisites

### System Requirements

- Proxmox VE 7.0 or later
- Root access to Proxmox nodes
- Internet connectivity for downloading cloud images
- Storage configured (local-lvm, NFS, Ceph, etc.)

### Required Commands

The script automatically checks for these commands:

- `qm` (Proxmox VM management)
- `wget` (downloading cloud images)
- `curl` (URL validation)
- `pvesm` (Proxmox storage management)

## Installation

### 1. Download the Script

```bash
# Download to Proxmox host
wget https://raw.githubusercontent.com/your-repo/create-cloud-template.sh
chmod +x create-cloud-template.sh

# Or copy the script manually
nano create-cloud-template.sh
# Paste script content and save
chmod +x create-cloud-template.sh
```

### 2. Verify Installation

```bash
# Test script
./create-cloud-template.sh --help

# Check prerequisites
./create-cloud-template.sh --vmid 9999 --help
```

## Storage Strategy

### Recommended Setup

**Templates**: Store on shared storage (NFS, Ceph, iSCSI)

- Accessible from all cluster nodes
- Centralized template management
- Easy backup and replication

**VMs**: Clone to local storage (local-lvm)

- Better I/O performance
- Reduced network overhead
- Node-specific optimization

### Example Storage Configuration

```bash
# Check available storage
pvesm status

# Typical setup:
# pve-nas (NFS)     - Shared storage for templates
# local-lvm (LVM)   - Local storage for VMs
# local (Directory) - Local storage for ISOs/backups
```

## Console Configuration

### VGA Console (Recommended for Proxmox)

This script configures templates with **VGA console** (`--vga std`) plus **serial port** (`--serial0 socket`) which provides:

✅ **VGA Console Advantages:**

- **Perfect interactive console access** via `qm terminal`
- **Easy troubleshooting** and boot process monitoring
- **Standard Proxmox console experience**
- **Compatible with Proxmox web console** (noVNC/SPICE)
- **No "starting serial terminal" issues**

✅ **Serial Port Benefits:**

- **Guest agent functionality** for automation
- **Network interface detection** via `qm guest cmd`
- **VM monitoring and management**

### Console Comparison

| Console Type     | Configuration                | Proxmox Experience | Troubleshooting  |
| ---------------- | ---------------------------- | ------------------ | ---------------- |
| **VGA + Serial** | `--vga std --serial0 socket` | ✅ **Perfect**     | ✅ **Excellent** |
| **Serial Only**  | `--vga serial0`              | ❌ Console issues  | ❌ Difficult     |

### Why This Configuration?

```bash
# Script creates VMs with optimal console setup:
qm create 9000 \
  --vga std \          # VGA console for interactive access
  --serial0 socket \   # Serial port for guest agent
  --agent enabled=1    # QEMU guest agent enabled
```

**Result**: Perfect console access AND automation capabilities!

## Basic Usage

### Command Syntax

```bash
./create-cloud-template.sh [OPTIONS]

# Required: Run as root on Proxmox host
sudo ./create-cloud-template.sh --vmid 9000 --name debian-12 --storage pve-nas
```

### Available Options

| Option          | Description                   | Default               | Example                            |
| --------------- | ----------------------------- | --------------------- | ---------------------------------- |
| `--vmid`        | VM ID (9000-9999 recommended) | 9000                  | `--vmid 9001`                      |
| `--name`        | Template name                 | cloud-template        | `--name debian-12`                 |
| `--description` | Template description          | "Cloud-Init Template" | `--description "Debian 12 Server"` |
| `--image-url`   | Cloud image URL               | Debian 12 latest      | See examples below                 |
| `--memory`      | RAM in MB                     | 1024                  | `--memory 2048`                    |
| `--cores`       | CPU cores                     | 1                     | `--cores 2`                        |
| `--storage`     | Storage name                  | local-lvm             | `--storage pve-nas`                |
| `--bridge`      | Network bridge                | vmbr0                 | `--bridge vmbr1`                   |
| `--cleanup`     | Remove downloads              | enabled               | `--cleanup`                        |
| `--no-cleanup`  | Keep downloads                | disabled              | `--no-cleanup`                     |
| `--force`       | Overwrite existing            | disabled              | `--force`                          |

## Template Creation Examples

### Debian 12 (Bookworm)

```bash
# Basic Debian 12 template with VGA console
./create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --description "Debian 12 Bookworm Cloud Template with VGA Console" \
  --storage "pve-nas" \
  --cleanup

# High-resource Debian template
./create-cloud-template.sh \
  --vmid 9001 \
  --name "debian-12-large" \
  --description "Debian 12 with 2GB RAM, 2 cores, VGA Console" \
  --storage "pve-nas" \
  --memory 2048 \
  --cores 2 \
  --cleanup
```

### Ubuntu 24.04 LTS (Noble)

```bash
# Ubuntu 24.04 template with VGA console
./create-cloud-template.sh \
  --vmid 9010 \
  --name "ubuntu-24-template" \
  --description "Ubuntu 24.04 LTS Noble with VGA Console" \
  --storage "pve-nas" \
  --image-url "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" \
  --cleanup

# Ubuntu 22.04 LTS template
./create-cloud-template.sh \
  --vmid 9011 \
  --name "ubuntu-22-template" \
  --description "Ubuntu 22.04 LTS Jammy with VGA Console" \
  --storage "pve-nas" \
  --image-url "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" \
  --cleanup
```

### Rocky Linux 9

```bash
# Rocky Linux 9 template with VGA console
./create-cloud-template.sh \
  --vmid 9020 \
  --name "rocky-9-template" \
  --description "Rocky Linux 9 with VGA Console" \
  --storage "pve-nas" \
  --image-url "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2" \
  --cleanup

# AlmaLinux 9 template
./create-cloud-template.sh \
  --vmid 9021 \
  --name "alma-9-template" \
  --description "AlmaLinux 9 with VGA Console" \
  --storage "pve-nas" \
  --image-url "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2" \
  --cleanup
```

### Batch Template Creation

```bash
#!/bin/bash
# create-all-templates.sh

templates=(
  "9000:debian-12:Debian 12 Bookworm:https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  "9010:ubuntu-24:Ubuntu 24.04 LTS:https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  "9011:ubuntu-22:Ubuntu 22.04 LTS:https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  "9020:rocky-9:Rocky Linux 9:https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
)

for template in "${templates[@]}"; do
  IFS=':' read -r vmid name description url <<< "$template"

  echo "Creating $name template (ID: $vmid) with VGA console..."
  ./create-cloud-template.sh \
    --vmid "$vmid" \
    --name "$name-template" \
    --description "$description Cloud Template with VGA Console" \
    --storage "pve-nas" \
    --image-url "$url" \
    --cleanup \
    --force

  echo "✓ $name template completed"
  echo "---"
done

echo "All templates with VGA console created successfully!"
```

## VM Cloning and Configuration

### Basic VM Cloning

```bash
# Clone to local storage (same node)
qm clone 9000 101 --name "web-server-01" --full --storage local-lvm

# Clone to different node's local storage (run from target node)
ssh pve02 'qm clone 9000 102 --name "web-server-02" --full --storage local-lvm'

# Clone to different node with shared storage
qm clone 9000 103 --name "shared-vm" --target pve02 --full --storage pve-nas
```

### VM Configuration Examples

#### Basic DHCP Configuration with Console Access

```bash
# Clone and configure with DHCP
qm clone 9000 101 --name "app-server" --full --storage local-lvm

qm set 101 \
  --ciuser ansible \
  --cipassword "secure-password" \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8

qm start 101

# Perfect console access with VGA configuration
qm terminal 101
# Login: ansible / secure-password
# Check IP: ip addr show
```

#### Static IP Configuration with Console Access

```bash
# Clone and configure with static IP
qm clone 9000 102 --name "db-server" --full --storage local-lvm

qm set 102 \
  --ciuser ansible \
  --cipassword "secure-password" \
  --ipconfig0 ip=10.10.1.100/24,gw=10.10.1.1 \
  --nameserver 10.10.1.1,8.8.8.8 \
  --searchdomain local.domain

qm start 102

# Console access for verification
qm terminal 102
# Login: ansible / secure-password
# Verify: ping google.com
```

#### SSH Key Configuration with Console Backup

```bash
# Clone and configure with SSH keys
qm clone 9000 103 --name "secure-server" --full --storage local-lvm

qm set 103 \
  --ciuser ansible \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8

qm start 103

# Check IP via console (VGA makes this easy)
qm terminal 103
# Note: SSH key auth only, may need to set password for console access
```

#### **Recommended: Combined Configuration (SSH Keys + Password)**

```bash
# Clone with both SSH keys and password (BEST PRACTICE)
qm clone 9000 104 --name "production-server" --full --storage local-lvm

qm set 104 \
  --ciuser ansible \
  --cipassword "backup-password" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=10.10.1.200/24,gw=10.10.1.1 \
  --nameserver 10.10.1.1,8.8.8.8 \
  --description "Production server with dual authentication and VGA console"

qm start 104

# Multiple access methods available:
# Console access: qm terminal 104 (ansible/backup-password)
# SSH access: ssh ansible@10.10.1.200 (key-based)
# Web console: Proxmox UI > VM 104 > Console (noVNC/SPICE)
```

## SSH Key Setup

### Setting Up SSH Keys

#### From Your Workstation (Mac/Linux)

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -C "your-email@domain.com"

# Copy public key to Proxmox
scp ~/.ssh/id_rsa.pub root@pve01:/root/.ssh/id_rsa.pub

# Set up SSH directories on Proxmox
ssh root@pve01 '
mkdir -p /root/.ssh /home/ansible/.ssh
chmod 700 /root/.ssh /home/ansible/.ssh
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
cp /root/.ssh/id_rsa.pub /home/ansible/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys /home/ansible/.ssh/authorized_keys
chown ansible:ansible /home/ansible/.ssh/authorized_keys
'

# Test SSH access
ssh root@pve01 'echo "SSH working!"'
```

#### On Proxmox Host

```bash
# Generate SSH key on Proxmox
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Set up for both root and ansible users
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
mkdir -p /home/ansible/.ssh
cp /root/.ssh/id_rsa.pub /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
```

## Cloud-Init Configuration

### Basic Cloud-Init Options

```bash
# User and authentication
--ciuser <username>              # Default user (e.g., ansible, ubuntu, admin)
--cipassword <password>          # Password for console access (recommended with VGA)
--sshkeys <key_file>             # SSH public key file

# Network configuration
--ipconfig0 ip=dhcp              # DHCP configuration
--ipconfig0 ip=10.1.1.100/24,gw=10.1.1.1  # Static IP
--nameserver <dns_servers>       # DNS servers (comma-separated)
--searchdomain <domain>          # DNS search domain

# Advanced options
--citype <type>                  # Cloud-init type (nocloud, configdrive)
--cicustom <options>             # Custom cloud-init files
```

### Advanced Cloud-Init Examples

#### Multi-Network Configuration

```bash
# Configure multiple network interfaces
qm set 105 \
  --ciuser ansible \
  --cipassword "password123" \
  --ipconfig0 ip=10.10.1.100/24,gw=10.10.1.1 \
  --ipconfig1 ip=192.168.1.100/24 \
  --nameserver 10.10.1.1,8.8.8.8

# Add second network interface
qm set 105 --net1 virtio,bridge=vmbr1

# Verify via console
qm terminal 105
# Inside VM: ip addr show
```

#### Custom User Data with VM Tools

```bash
# Create custom user data file for QEMU guest agent
cat > /var/lib/vz/snippets/install-tools.yml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - curl
  - wget
  - vim
  - htop
  - net-tools

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - timedatectl set-timezone America/New_York

write_files:
  - content: |
      Welcome to the automated server!
      Generated on $(date)
      Console access: VGA configured
      Guest agent: Enabled
    path: /etc/motd
    permissions: '0644'
EOF

# Use custom user data
qm set 106 \
  --ciuser ansible \
  --cipassword "password123" \
  --ipconfig0 ip=dhcp \
  --cicustom "user=local:snippets/install-tools.yml"

qm start 106

# Monitor installation via console
qm terminal 106
# Check guest agent: systemctl status qemu-guest-agent
```

### Installing QEMU Guest Agent

#### Via Cloud-Init (Recommended)

```bash
# Create cloud-init script to install guest agent
cat > /var/lib/vz/snippets/install-agent.yml << 'EOF'
#cloud-config
package_update: true
packages:
  - qemu-guest-agent

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - echo "Guest agent installed and started" >> /tmp/cloud-init.log
EOF

# Configure VM to use the script
qm set 107 \
  --ciuser ansible \
  --cipassword "password123" \
  --ipconfig0 ip=dhcp \
  --cicustom "user=local:snippets/install-agent.yml"

qm start 107

# Watch installation via console
qm terminal 107
# After boot: sudo systemctl status qemu-guest-agent
```

#### Manual Installation (Easy with VGA Console)

```bash
# Console into VM (VGA console makes this easy)
qm terminal 107
# Login: ansible/password123

# Or SSH into VM
ssh ansible@<vm_ip>

# Debian/Ubuntu
sudo apt update
sudo apt install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Rocky Linux/AlmaLinux
sudo dnf install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Verify installation
sudo systemctl status qemu-guest-agent

# Test guest agent functionality (from Proxmox host)
qm guest cmd 107 network-get-interfaces
qm guest cmd 107 info
```

## Cluster Operations

### Template Management Across Nodes

```bash
# List templates cluster-wide
pvesh get /cluster/resources --type vm | grep template

# Check template accessibility from different nodes
for node in pve01 pve02 pve03; do
  echo "Node: $node"
  ssh $node 'qm list | grep template'
  echo "Console test: ssh $node \"qm terminal <vmid>\""
  echo "---"
done

# Backup templates
vzdump 9000 9010 9020 --storage pve-nas --compress zstd
```

### Cross-Node VM Deployment with Console Access

```bash
# Deploy VMs across cluster nodes
nodes=("pve01" "pve02" "pve03")
template_id=9000

for i in {0..2}; do
  node=${nodes[$i]}
  vm_id=$((201 + i))

  echo "Deploying VM $vm_id on $node with VGA console..."
  ssh $node "qm clone $template_id $vm_id --name web-$node --full --storage local-lvm"
  ssh $node "qm set $vm_id --ciuser ansible --cipassword password123 --ipconfig0 ip=dhcp"
  ssh $node "qm start $vm_id"

  # Console access available on each node
  echo "Console access: ssh $node 'qm terminal $vm_id'"
  echo "Web console: https://$node:8006 > VM $vm_id > Console"
done
```

### High Availability Setup

```bash
# Create HA-enabled VMs with console access
qm clone 9000 301 --name "ha-web-01" --full --storage pve-nas

qm set 301 \
  --ciuser ansible \
  --cipassword "ha-password" \
  --ipconfig0 ip=10.10.1.101/24,gw=10.10.1.1

# Add to HA group
ha-manager add vm:301 --state started --group production

qm start 301

# Console access works regardless of which node it's running on
qm terminal 301
# Web console also available from any cluster node
```

## Troubleshooting

### Console Access (VGA Configuration Benefits)

With VGA console configuration, troubleshooting is much easier:

```bash
# Perfect console access for troubleshooting
qm terminal 201

# Inside VM console (no login issues):
# - Check network: ip addr show
# - Test connectivity: ping google.com
# - View logs: sudo journalctl -f
# - Check cloud-init: sudo cloud-init status
# - Monitor processes: htop
```

### Common Issues and Solutions

#### Template Creation Fails

```bash
# Check storage space
pvesm status -storage pve-nas

# Verify network connectivity
curl -I https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Check permissions
ls -la /mnt/pve/pve-nas/

# Test write access
touch /mnt/pve/pve-nas/test-file && rm /mnt/pve/pve-nas/test-file
```

#### VM Won't Start

```bash
# Check VM configuration
qm config <vmid>

# Verify VGA console is set
qm config <vmid> | grep vga
# Should show: vga: std

# Check storage
qm rescan

# View VM logs
tail -f /var/log/pve/tasks/active

# Console into VM for direct troubleshooting
qm terminal <vmid>
```

#### Console Access Issues (Rare with VGA)

```bash
# If console still shows issues (very rare)
qm stop 201
qm set 201 --vga std  # Ensure VGA is set
qm start 201
qm terminal 201

# Alternative: Use Proxmox web console
# Web UI > VM > Console > Select "noVNC" or "SPICE"
```

#### SSH Connection Issues

```bash
# Use console to check VM network (VGA advantage)
qm terminal <vmid>
# Inside VM:
ip addr show
ping google.com
systemctl status sshd

# Verify SSH key setup from Proxmox
cat /root/.ssh/id_rsa.pub

# Check guest agent (if installed)
qm guest cmd <vmid> network-get-interfaces
```

#### Cloud-Init Not Working

```bash
# Easy troubleshooting with VGA console
qm terminal <vmid>

# Inside VM:
sudo cloud-init status
sudo cloud-init logs

# Check detailed logs
sudo cat /var/log/cloud-init-output.log
sudo journalctl -u cloud-init

# Regenerate cloud-init
sudo cloud-init clean
sudo reboot

# Monitor reboot via console
qm terminal <vmid>
```

### Debug Mode

```bash
# Run script with debug output
bash -x ./create-cloud-template.sh --vmid 9999 --name debug-test

# Test VM configuration
qm config 9999 | grep -E "(vga|serial|agent)"
# Should show:
# agent: 1
# serial0: socket
# vga: std
```

## Best Practices

### Console Configuration Best Practices

1. **Always Use VGA Console**: Best for Proxmox interactive management
2. **Keep Serial Port**: Maintain guest agent functionality (`--serial0 socket`)
3. **Dual Authentication**: SSH keys + password for maximum flexibility
4. **Test Console Access**: Verify `qm terminal` works before production
5. **Document Access Methods**: Both console and SSH for different scenarios

### Template Management

1. **Use Consistent Naming**: `os-version-template` (e.g., `debian-12-template`)
2. **Include Console Info**: Document VGA console in descriptions
3. **Version Templates**: Include date/version in description
4. **Regular Updates**: Refresh templates monthly with latest images
5. **Backup Templates**: Regular backup schedule for template storage
6. **Test Console Access**: Verify console works on new templates

### VM Deployment

1. **Resource Planning**: Right-size CPU and memory for workload
2. **Storage Strategy**: Local storage for VMs, shared for templates
3. **Console Access**: Always include password for console troubleshooting
4. **Network Segmentation**: Use appropriate VLANs and bridges
5. **Security**: SSH keys for automation, passwords for console access
6. **Monitoring**: Implement proper monitoring and alerting

### Security Considerations

1. **Dual Authentication**: SSH keys for automation, passwords for console
2. **Console Security**: Use strong passwords for console access
3. **User Management**: Create dedicated service accounts
4. **Network Security**: Implement firewalls and network policies
5. **Updates**: Regular security updates via cloud-init or automation
6. **Access Control**: Limit Proxmox API access and permissions

### Performance Optimization

1. **Console Choice**: VGA for usability without performance penalty
2. **Storage**: Use local storage for VM disks
3. **CPU**: Match CPU type to workload requirements
4. **Memory**: Avoid over-allocation, use balloon driver
5. **Network**: Use virtio drivers for best performance
6. **Guest Agents**: Install QEMU guest agent for better management

### Automation Ready

This VGA console setup provides the foundation for:

- **Interactive Management**: Easy troubleshooting via console
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration management via SSH
- **CI/CD Pipelines**: Automated deployments
- **Kubernetes**: Container orchestration platforms
- **Monitoring**: Prometheus, Grafana, etc.

---

## Quick Reference

### Essential Commands

```bash
# Create template with VGA console
./create-cloud-template.sh --vmid 9000 --name debian-12 --storage pve-nas

# Clone VM
qm clone 9000 101 --name my-vm --full --storage local-lvm

# Configure cloud-init (dual auth recommended)
qm set 101 --ciuser ansible --cipassword pass123 --sshkeys /root/.ssh/id_rsa.pub --ipconfig0 ip=dhcp

# Start VM
qm start 101

# Console access (VGA configured - no issues)
qm terminal 101

# Check status
qm status 101

# Get IP (multiple methods)
qm terminal 101  # Then: ip addr show
qm guest cmd 101 network-get-interfaces  # If guest agent installed

# SSH to VM
ssh ansible@<vm-ip>
```

### Console Access Methods

```bash
# Direct console access (VGA)
qm terminal <vmid>

# Web console access
# Proxmox Web UI > VM > Console > noVNC/SPICE

# SSH access (key-based)
ssh ansible@<vm-ip>

# Emergency console access
# Physical console if available
```

### Template Configuration

| Component | Setting                      | Purpose                      |
| --------- | ---------------------------- | ---------------------------- |
| VGA       | `--vga std`                  | Interactive console access   |
| Serial    | `--serial0 socket`           | Guest agent functionality    |
| Agent     | `--agent enabled=1`          | VM management and monitoring |
| Network   | `--net0 virtio,bridge=vmbr0` | Network connectivity         |

### Useful Templates

| Template ID | OS            | Console      | Use Case                        |
| ----------- | ------------- | ------------ | ------------------------------- |
| 9000        | Debian 12     | VGA + Serial | General purpose, web servers    |
| 9010        | Ubuntu 24.04  | VGA + Serial | Modern applications, containers |
| 9011        | Ubuntu 22.04  | VGA + Serial | LTS stability, enterprise       |
| 9020        | Rocky Linux 9 | VGA + Serial | Enterprise Linux, legacy apps   |

### Storage Layout

```
pve-nas (shared)     -> Templates (9000-9999) with VGA console
local-lvm (local)    -> Production VMs (100-999)
local (directory)    -> ISOs, backups
```

### Troubleshooting Quick Guide

| Issue                  | Solution                              |
| ---------------------- | ------------------------------------- |
| Console won't open     | `qm terminal <vmid>` (VGA configured) |
| Can't see boot process | VGA console shows everything          |
| Need to check IP       | Console: `ip addr show`               |
| SSH not working        | Console: check network, SSH status    |
| Cloud-init failed      | Console: `sudo cloud-init logs`       |
| VM won't boot          | Console: watch boot process           |

This comprehensive setup with **VGA console configuration** provides the perfect foundation for Proxmox virtualization with excellent interactive access and full automation capabilities!
