# Cloud-Init Configurations

Ready-to-use cloud-init scripts for bootstrapping Proxmox VMs. Focuses on user setup, SSH keys, passwordless sudo, and essential tools.

## 📁 Available Configurations

| File                     | Purpose                      | Setup Time | Includes                                                 |
| ------------------------ | ---------------------------- | ---------- | -------------------------------------------------------- |
| `basic-bootstrap.yml`    | Essential server setup       | ~5 minutes | Users, SSH keys, qemu-agent, basic tools, firewall       |
| `enhanced-bootstrap.yml` | Development/production ready | ~8 minutes | Everything above + Docker, security hardening, dev tools |

## 🎯 Core Features (Both Configurations)

- ✅ **User Setup**: `admin` and `ansible` users with passwordless sudo
- ✅ **SSH Keys**: Key-based authentication configured
- ✅ **QEMU Guest Agent**: Enabled for Proxmox management and monitoring
- ✅ **Basic Security**: UFW firewall configured
- ✅ **Essential Tools**: vim, git, htop, curl, wget, net-tools

## 📋 Setup Instructions

### Step 1: Copy Cloud-Init Files to Snippets Storage

Since the repository is cloned on your Proxmox server, simply copy the files locally:

```bash
# Navigate to the repository
cd /opt/proxmox-scripts

# Copy cloud-init files to local snippets storage
cp cloud-init/*.yml /var/lib/vz/snippets/

# Set proper permissions
chmod 644 /var/lib/vz/snippets/*.yml

# Verify files are in place
ls -la /var/lib/vz/snippets/*.yml
```

#### For Shared Storage (if using cluster)

```bash
# Copy to shared storage snippets directory
cp cloud-init/*.yml /mnt/pve/your-shared-storage/snippets/

# Set proper permissions
chmod 644 /mnt/pve/your-shared-storage/snippets/*.yml
```

### Step 2: Enable Snippets Content Type

Ensure your Proxmox storage supports the `snippets` content type:

```bash
# Add snippets content type to local storage
pvesm set local -content backup,vztmpl,iso,snippets

# For shared storage (example)
pvesm set your-shared-storage -content backup,images,snippets

# Verify the change
pvesm status -storage local
```

**Or via Web Interface:** Datacenter → Storage → [storage-name] → Edit → Content → ✓ Snippets

## 🚀 VM Deployment Examples

### Basic Server Deployment

```bash
# 1. Clone your template
qm clone 9000 101 --name "basic-server" --full --storage local-lvm

# 2. Configure with cloud-init
qm set 101 \
  --ciuser admin \
  --cipassword "changeme123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --cicustom "user=local:snippets/basic-bootstrap.yml"

# 3. Start the VM
qm start 101

# 4. Access via console (VGA optimized)
qm terminal 101

# 5. SSH access with your keys
ssh admin@<vm-ip>
```

### Enhanced Development Server

```bash
# Clone template with more resources for development
qm clone 9000 102 --name "dev-server" --full --storage local-lvm

# Configure with enhanced bootstrap (includes Docker)
qm set 102 \
  --ciuser admin \
  --cipassword "dev123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --memory 4096 \
  --cores 2 \
  --cicustom "user=local:snippets/enhanced-bootstrap.yml"

# Start and access
qm start 102
qm terminal 102  # Or: ssh admin@<vm-ip>
```

### Static IP Configuration

```bash
# Clone template
qm clone 9000 103 --name "web-server" --full --storage local-lvm

# Configure with static IP
qm set 103 \
  --ciuser admin \
  --cipassword "web123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=192.168.1.100/24,gw=192.168.1.1 \
  --nameserver 192.168.1.1,8.8.8.8 \
  --memory 4096 \
  --cores 2 \
  --cicustom "user=local:snippets/enhanced-bootstrap.yml"

# Start VM
qm start 103
```

### Cluster Deployment (Shared Storage)

```bash
# Deploy VM on different node using shared storage cloud-init
ssh pve02 'qm clone 9000 201 --name "cluster-server" --full --storage local-lvm'

ssh pve02 'qm set 201 \
  --ciuser admin \
  --cipassword "cluster123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --cicustom "user=shared-storage:snippets/basic-bootstrap.yml"'

ssh pve02 'qm start 201'
```

## 🔧 Customization Guide

### 1. Update SSH Keys (Critical)

**Before first use**, replace placeholder SSH keys with your actual keys:

```bash
# Get your SSH public key
cat ~/.ssh/id_rsa.pub

# Edit both cloud-init files
vim /var/lib/vz/snippets/basic-bootstrap.yml
vim /var/lib/vz/snippets/enhanced-bootstrap.yml

# Replace this line in both files:
# - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... # Replace with your SSH public key
# With your actual public key
```

### 2. Customize Users

Modify usernames and permissions in the YAML files:

```yaml
users:
  - name: your-admin-user # Change from 'admin'
    groups: [sudo, docker] # Add/remove groups as needed
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - your-ssh-key-here
```

### 3. Adjust System Settings

```yaml
timezone: America/New_York # Change to your timezone
locale: en_US.UTF-8 # Change to your locale
```

### 4. Add Custom Packages

```yaml
packages:
  # Keep essential packages
  - qemu-guest-agent
  - curl
  - wget
  # Add your custom packages
  - your-custom-package
  - another-tool
```

## 📊 What Gets Configured

### Basic Bootstrap (`basic-bootstrap.yml`)

- ✅ **Users**: `admin`, `ansible` (both with passwordless sudo)
- ✅ **SSH**: Key-based authentication enabled, password auth for console access
- ✅ **Tools**: Essential system utilities (vim, git, htop, curl, wget, net-tools)
- ✅ **Services**: qemu-guest-agent, UFW firewall (SSH only)
- ✅ **Management**: Simple status script (`server-status`)

### Enhanced Bootstrap (`enhanced-bootstrap.yml`)

- ✅ **Everything from basic** +
- ✅ **Docker**: Container platform with Docker Compose
- ✅ **Additional Users**: `monitor` user with limited sudo for monitoring
- ✅ **Security**: fail2ban, enhanced firewall rules
- ✅ **Development Tools**: python3, node.js, npm, jq, tree
- ✅ **Management Scripts**: Enhanced monitoring, Docker helpers, backup tools

## 🎯 Post-Deployment Verification

### 1. Monitor Cloud-Init Progress

```bash
# Watch cloud-init via console (VGA console advantage)
qm terminal <vmid>

# Inside VM, check cloud-init status
sudo cloud-init status

# View cloud-init logs
sudo cloud-init logs

# Watch progress in real-time
sudo tail -f /var/log/cloud-init-output.log
```

### 2. Verify SSH Access

```bash
# SSH with your configured key
ssh admin@<server-ip>

# Test passwordless sudo
sudo whoami

# Check user groups
groups
```

### 3. Test Management Scripts

```bash
# Basic setup
server-status

# Enhanced setup
server-status
docker-helper status  # If Docker is installed
backup-system-state
```

### 4. Verify Services

```bash
# Check essential services
sudo systemctl status qemu-guest-agent
sudo systemctl status ufw

# Enhanced setup - check additional services
sudo systemctl status docker
sudo systemctl status fail2ban
```

## 🚨 Storage Reference Guide

| Storage Type | Snippets Path                  | VM Reference                      |
| ------------ | ------------------------------ | --------------------------------- |
| **Local**    | `/var/lib/vz/snippets/`        | `local:snippets/filename.yml`     |
| **NFS**      | `/mnt/pve/nfs-name/snippets/`  | `nfs-name:snippets/filename.yml`  |
| **Ceph**     | `/mnt/pve/ceph-name/snippets/` | `ceph-name:snippets/filename.yml` |

## 🔍 Troubleshooting

### Cloud-Init File Not Found

```bash
# Check if files exist in snippets storage
ls -la /var/lib/vz/snippets/*.yml

# Verify storage supports snippets
pvesm status -storage local

# Check VM configuration
qm config <vmid> | grep cicustom
```

### Cloud-Init Not Running

```bash
# Console into VM to debug (VGA console advantage)
qm terminal <vmid>

# Check cloud-init status
sudo cloud-init status
sudo cloud-init logs

# View detailed logs
sudo cat /var/log/cloud-init-output.log

# Force cloud-init to run again
sudo cloud-init clean
sudo reboot
```

### SSH Access Issues

```bash
# Use console for debugging
qm terminal <vmid>

# Inside VM, check SSH service and keys
sudo systemctl status ssh
cat ~/.ssh/authorized_keys

# Check network configuration
ip addr show
ping google.com
```

## 📋 Quick Reference Commands

```bash
# Setup cloud-init files
cp cloud-init/*.yml /var/lib/vz/snippets/
chmod 644 /var/lib/vz/snippets/*.yml
pvesm set local -content backup,vztmpl,iso,snippets

# Deploy VM
qm clone 9000 101 --name my-vm --full --storage local-lvm
qm set 101 --cicustom "user=local:snippets/basic-bootstrap.yml" --ciuser admin --ipconfig0 ip=dhcp --sshkeys /root/.ssh/id_rsa.pub
qm start 101

# Access VM
qm terminal 101  # Console access
ssh admin@<vm-ip>  # SSH access
```

## 🎉 Success Indicators

When everything works correctly, you should have:

- ✅ **SSH access** with your keys (no password needed)
- ✅ **Passwordless sudo** for admin and ansible users
- ✅ **Console access** working perfectly via `qm terminal`
- ✅ **Guest agent** responding to Proxmox commands
- ✅ **Custom MOTD** showing when you login
- ✅ **Management scripts** available and working

## 🔮 Advanced Automation (Optional)

Once comfortable with manual VM deployment, you can integrate with Infrastructure as Code tools like **Terraform** for even greater automation. The cloud-init files work perfectly with automation tools.

Ready for rapid Proxmox VM deployment! 🚀
