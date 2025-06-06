# Proxmox Cloud Template Creation Script

A comprehensive script for creating cloud-init templates in Proxmox VE clusters with **optimized VGA console access**. This script automates the entire process of downloading cloud images, creating VMs, importing disks, configuring cloud-init, and converting to templates.

## 🎯 Perfect for Automated VM Deployment

This script creates templates optimized for rapid VM deployment:

- **VGA console access** for easy troubleshooting via `qm terminal`
- **Cloud-init ready** for automated VM bootstrap
- **Guest agent configured** for Proxmox integration
- **Works with manual deployment** or automation tools

**💡 Tip:** Combine with the **[cloud-init configurations](../cloud-init/README.md)** in this repository for complete VM automation!

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Storage Strategy](#storage-strategy)
- [Console Configuration](#console-configuration)
- [Basic Usage](#basic-usage)
- [Template Creation Examples](#template-creation-examples)
- [VM Deployment Examples](#vm-deployment-examples)
- [SSH Key Setup](#ssh-key-setup)
- [Cloud-Init Integration](#cloud-init-integration)
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
- **Deployed with standard Proxmox commands**

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

### 1. Clone Repository

```bash
# Clone repository on Proxmox host
cd /opt
git clone https://github.com/dougjaworski/proxmox-scripts.git
cd proxmox-scripts

# Make script executable
chmod +x cloud-templates/create-cloud-template.sh

# Test script
./cloud-templates/create-cloud-template.sh --help
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
# shared-storage (NFS)  - Shared storage for templates
# local-lvm (LVM)       - Local storage for VMs
# local (Directory)     - Local storage for ISOs/backups
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

## Basic Usage

### Command Syntax

```bash
./create-cloud-template.sh [OPTIONS]

# Required: Run as root on Proxmox host
sudo ./cloud-templates/create-cloud-template.sh --vmid 9000 --name debian-12 --storage local-lvm
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
| `--storage`     | Storage name                  | local-lvm             | `--storage shared-storage`         |
| `--bridge`      | Network bridge                | vmbr0                 | `--bridge vmbr1`                   |
| `--cleanup`     | Remove downloads              | enabled               | `--cleanup`                        |
| `--no-cleanup`  | Keep downloads                | disabled              | `--no-cleanup`                     |
| `--force`       | Overwrite existing            | disabled              | `--force`                          |

## Template Creation Examples

### Debian 12 (Bookworm)

```bash
# Basic Debian 12 template with VGA console
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --description "Debian 12 Bookworm Cloud Template with VGA Console" \
  --storage "local-lvm" \
  --cleanup

# High-resource Debian template
./cloud-templates/create-cloud-template.sh \
  --vmid 9001 \
  --name "debian-12-large" \
  --description "Debian 12 with 2GB RAM, 2 cores, VGA Console" \
  --storage "local-lvm" \
  --memory 2048 \
  --cores 2 \
  --cleanup
```

### Ubuntu 24.04 LTS (Noble)

```bash
# Ubuntu 24.04 template with VGA console
./cloud-templates/create-cloud-template.sh \
  --vmid 9010 \
  --name "ubuntu-24-template" \
  --description "Ubuntu 24.04 LTS Noble with VGA Console" \
  --storage "local-lvm" \
  --image-url "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" \
  --cleanup

# Ubuntu 22.04 LTS template
./cloud-templates/create-cloud-template.sh \
  --vmid 9011 \
  --name "ubuntu-22-template" \
  --description "Ubuntu 22.04 LTS Jammy with VGA Console" \
  --storage "local-lvm" \
  --image-url "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" \
  --cleanup
```

### Rocky Linux 9

```bash
# Rocky Linux 9 template with VGA console
./cloud-templates/create-cloud-template.sh \
  --vmid 9020 \
  --name "rocky-9-template" \
  --description "Rocky Linux 9 with VGA Console" \
  --storage "local-lvm" \
  --image-url "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2" \
  --cleanup
```

## VM Deployment Examples

### Basic VM Deployment with Cloud-Init

```bash
# 1. Clone template
qm clone 9000 101 --name "web-server-01" --full --storage local-lvm

# 2. Configure with cloud-init (using repository cloud-init files)
qm set 101 \
  --ciuser admin \
  --cipassword "secure-password" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --cicustom "user=local:snippets/basic-bootstrap.yml"

# 3. Start VM
qm start 101

# 4. Access via perfect console (VGA configured)
qm terminal 101
# Login: admin / secure-password (or SSH with keys)
# Check status: server-status
```

### Static IP Configuration

```bash
# Clone and configure with static IP
qm clone 9000 102 --name "db-server" --full --storage local-lvm

qm set 102 \
  --ciuser admin \
  --cipassword "secure-password" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=10.10.1.100/24,gw=10.10.1.1 \
  --nameserver 10.10.1.1,8.8.8.8 \
  --cicustom "user=local:snippets/enhanced-bootstrap.yml"

qm start 102

# Console access for verification
qm terminal 102
# Verify: ping google.com, docker --version
```

### Development Server Deployment

```bash
# Clone with more resources for development
qm clone 9000 103 --name "dev-server" --full --storage local-lvm

qm set 103 \
  --ciuser admin \
  --cipassword "dev-password" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --memory 4096 \
  --cores 2 \
  --cicustom "user=local:snippets/enhanced-bootstrap.yml"

qm start 103

# Access development environment
qm terminal 103
# Available: Docker, Python, Node.js, development tools
```

## SSH Key Setup

### Setting Up SSH Keys on Proxmox

```bash
# Generate SSH key on Proxmox if you don't have one
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Set up authorized_keys
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Test SSH key setup
ssh-add /root/.ssh/id_rsa
```

## Cloud-Init Integration

### Using Repository Cloud-Init Files

This repository includes ready-to-use cloud-init configurations:

```bash
# 1. Copy cloud-init files to snippets storage
cp cloud-init/*.yml /var/lib/vz/snippets/
chmod 644 /var/lib/vz/snippets/*.yml

# 2. Enable snippets content type
pvesm set local -content backup,vztmpl,iso,snippets

# 3. Deploy VMs with cloud-init
qm clone 9000 101 --name my-vm --full --storage local-lvm
qm set 101 --cicustom "user=local:snippets/basic-bootstrap.yml" --ciuser admin --ipconfig0 ip=dhcp
qm start 101
```

### Cloud-Init Options

```bash
# Basic configuration
--ciuser admin                              # Default user
--cipassword "password"                     # Password for console access
--sshkeys /root/.ssh/id_rsa.pub            # SSH public key file
--ipconfig0 ip=dhcp                         # DHCP configuration
--ipconfig0 ip=10.1.1.100/24,gw=10.1.1.1   # Static IP
--nameserver 8.8.8.8,1.1.1.1              # DNS servers
--cicustom "user=local:snippets/file.yml"  # Custom cloud-init file
```

## Cluster Operations

### Template Management Across Nodes

```bash
# Create template on shared storage (accessible from all nodes)
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-cluster" \
  --storage "shared-storage"

# Deploy VMs from any cluster node
ssh pve02 'qm clone 9000 201 --name web-server-node2 --full --storage local-lvm'
ssh pve03 'qm clone 9000 301 --name web-server-node3 --full --storage local-lvm'

# Configure and start from respective nodes
ssh pve02 'qm set 201 --cicustom "user=shared-storage:snippets/basic-bootstrap.yml" --ciuser admin'
ssh pve02 'qm start 201'
```

## Troubleshooting

### Console Access (VGA Configuration Benefits)

With VGA console configuration, troubleshooting is much easier:

```bash
# Perfect console access for troubleshooting
qm terminal 101

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
pvesm status -storage local-lvm

# Verify network connectivity
curl -I https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Check permissions
ls -la /var/lib/vz/template/

# Test write access
touch /var/lib/vz/template/test-file && rm /var/lib/vz/template/test-file
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

# Regenerate cloud-init
sudo cloud-init clean
sudo reboot
```

## Best Practices

### Template Management

1. **Use Consistent Naming**: `os-version-template` (e.g., `debian-12-template`)
2. **Include Console Info**: Document VGA console in descriptions
3. **Version Templates**: Include date/version in description
4. **Regular Updates**: Refresh templates monthly with latest images
5. **Backup Templates**: Regular backup schedule for template storage

### VM Deployment

1. **Resource Planning**: Right-size CPU and memory for workload
2. **Storage Strategy**: Local storage for VMs, shared for templates
3. **Console Access**: Always include password for console troubleshooting
4. **Network Segmentation**: Use appropriate VLANs and bridges
5. **Security**: SSH keys for automation, passwords for console access

### Performance Optimization

1. **Console Choice**: VGA for usability without performance penalty
2. **Storage**: Use local storage for VM disks
3. **CPU**: Match CPU type to workload requirements
4. **Memory**: Avoid over-allocation, use balloon driver
5. **Network**: Use virtio drivers for best performance

## 🔮 Advanced Automation (Optional)

Once comfortable with manual template creation and VM deployment, you can integrate with Infrastructure as Code tools like **Terraform** for even greater automation. The templates and cloud-init files work perfectly with automation tools.

---

## Quick Reference

### Essential Commands

```bash
# Create template with VGA console
./cloud-templates/create-cloud-template.sh --vmid 9000 --name debian-12 --storage local-lvm

# Set up cloud-init files
cp cloud-init/*.yml /var/lib/vz/snippets/
pvesm set local -content backup,vztmpl,iso,snippets

# Clone and deploy VM
qm clone 9000 101 --name my-vm --full --storage local-lvm
qm set 101 --cicustom "user=local:snippets/basic-bootstrap.yml" --ciuser admin --ipconfig0 ip=dhcp
qm start 101

# Access VM
qm terminal 101  # Perfect console access
ssh admin@<vm-ip>  # SSH access with keys
```

This comprehensive setup with **VGA console configuration** provides the perfect foundation for Proxmox virtualization with excellent interactive access and automation capabilities!
