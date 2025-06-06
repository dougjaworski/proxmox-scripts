# Installation Guide

This guide provides detailed installation instructions for the Proxmox Scripts repository across different Proxmox configurations.

## 📋 Prerequisites

### System Requirements
- Proxmox VE 7.0 or later (tested on PVE 8.4.0)
- Root access to Proxmox nodes
- Internet connectivity for downloading cloud images
- Git installed on Proxmox nodes

### Install Git (if not present)
```bash
# Check if git is installed
which git

# Install git if needed (Debian/Ubuntu based Proxmox)
apt update && apt install -y git
```

## 🏗️ Installation Options

### Option 1: Shared Storage Installation (Recommended for Clusters)

**Best for**: Proxmox clusters with shared storage (NFS, Ceph, GlusterFS, etc.)

**Benefits**:
- ✅ Scripts accessible from all cluster nodes
- ✅ Central management and updates
- ✅ Templates accessible cluster-wide
- ✅ Consistent script versions across nodes

#### Step 1: Identify Your Shared Storage
```bash
# List available storage
pvesm status

# Example output:
# Name             Type     Status           Total            Used       Available        %
# local            dir      active        92182492         4857340        82594492    5.27%
# local-lvm        lvmthin  active        92182492        15097344        77085148   16.39%
# pve-nas          nfs      active       976762624       267628544       709134080   27.39%
# backup-storage   cifs     active       488378368       167628544       320749824   34.32%
```

#### Step 2: Install to Shared Storage
```bash
# Navigate to your shared storage mount point
# Replace 'pve-nas' with your shared storage name
cd /mnt/pve/pve-nas

# Clone the repository
git clone https://github.com/yourusername/proxmox-scripts.git scripts

# Navigate to scripts directory
cd scripts

# Make scripts executable
chmod +x cloud-templates/*.sh
chmod +x examples/*.sh 2>/dev/null || true

# Verify installation
./cloud-templates/create-cloud-template.sh --help
```

#### Step 3: Access from Any Cluster Node
```bash
# From any cluster node, navigate to scripts
cd /mnt/pve/pve-nas/scripts

# Scripts are now available on all nodes
./cloud-templates/create-cloud-template.sh --vmid 9000 --name debian-12 --storage pve-nas
```

### Option 2: Local Installation (Per-Node or Single Node)

**Best for**: Single Proxmox nodes or when you prefer local script copies

**Benefits**:
- ✅ No dependency on shared storage
- ✅ Works on single-node setups
- ✅ Local control over script versions
- ✅ Can customize per node if needed

#### Step 1: Install to /opt Directory
```bash
# Navigate to /opt directory
cd /opt

# Clone the repository
git clone https://github.com/yourusername/proxmox-scripts.git

# Navigate to scripts directory
cd proxmox-scripts

# Make scripts executable
chmod +x cloud-templates/*.sh
chmod +x examples/*.sh 2>/dev/null || true

# Verify installation
./cloud-templates/create-cloud-template.sh --help
```

#### Step 2: Create Convenient Access (Optional)
```bash
# Create symlink for easy access
ln -s /opt/proxmox-scripts/cloud-templates/create-cloud-template.sh /usr/local/bin/create-cloud-template

# Now you can run from anywhere
create-cloud-template --help

# Or add to PATH
echo 'export PATH="/opt/proxmox-scripts/cloud-templates:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Step 3: Install on Additional Nodes (For Clusters)
```bash
# For each additional node in cluster
for node in pve02 pve03; do
    echo "Installing on $node..."
    ssh $node 'cd /opt && git clone https://github.com/yourusername/proxmox-scripts.git'
    ssh $node 'chmod +x /opt/proxmox-scripts/cloud-templates/*.sh'
    echo "✓ $node installation complete"
done
```

## 🎯 Post-Installation Setup

### SSH Key Setup (Recommended)
Set up SSH keys for cloud-init VMs:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Set up authorized_keys
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# For cluster setups, copy to all nodes
for node in pve02 pve03; do
    scp /root/.ssh/id_rsa.pub $node:/root/.ssh/
    ssh $node 'cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys; chmod 600 /root/.ssh/authorized_keys'
done
```

### Storage Configuration Verification
```bash
# Verify storage setup
pvesm status

# Test storage access (replace 'pve-nas' with your storage)
touch /mnt/pve/pve-nas/test-file && rm /mnt/pve/pve-nas/test-file
echo "✓ Storage write test successful"
```

## 🔧 Configuration Examples

### Example 1: Cluster with NFS Storage
```bash
# Install scripts on NFS storage
cd /mnt/pve/nfs-storage
git clone https://github.com/yourusername/proxmox-scripts.git scripts

# Create templates on shared storage
./scripts/cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "nfs-storage"

# Clone VMs to local storage (from any node)
qm clone 9000 101 --name "web-server" --full --storage local-lvm
```

### Example 2: Single Node Setup
```bash
# Install locally
cd /opt
git clone https://github.com/yourusername/proxmox-scripts.git

# Create templates locally
./proxmox-scripts/cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "local-lvm"

# Clone locally
qm clone 9000 101 --name "web-server" --full --storage local-lvm
```

### Example 3: Mixed Environment
```bash
# Scripts on shared storage
cd /mnt/pve/shared-storage/scripts

# Templates on shared storage, VMs on local
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "shared-storage"

# Clone to local storage for performance
qm clone 9000 101 --name "production-vm" --full --storage local-lvm
```

## 🔄 Updates and Maintenance

### Updating Scripts
```bash
# Navigate to installation directory
cd /mnt/pve/pve-nas/scripts  # Or /opt/proxmox-scripts

# Pull latest updates
git pull origin main

# Verify functionality
./cloud-templates/create-cloud-template.sh --help
```

### Backup Your Installation
```bash
# Create backup of scripts directory
tar -czf proxmox-scripts-backup-$(date +%Y%m%d).tar.gz proxmox-scripts/

# Store backup safely
mv proxmox-scripts-backup-*.tar.gz /path/to/backup/storage/
```

## 🚨 Troubleshooting Installation

### Permission Issues
```bash
# Fix permissions if needed
chmod +x /path/to/scripts/cloud-templates/*.sh
chown root:root /path/to/scripts/cloud-templates/*.sh
```

### Storage Access Issues
```bash
# Check storage status
pvesm status -storage your-storage-name

# Test write access
touch /mnt/pve/your-storage/test && rm /mnt/pve/your-storage/test
```

### Git Issues
```bash
# If git clone fails, check connectivity
curl -I https://github.com

# Alternative: download as ZIP
wget https://github.com/yourusername/proxmox-scripts/archive/main.zip
unzip main.zip
mv proxmox-scripts-main proxmox-scripts
```

## ✅ Verification

### Test Installation
```bash
# Navigate to installation directory
cd /path/to/proxmox-scripts

# Test script help
./cloud-templates/create-cloud-template.sh --help

# Test prerequisites check
./cloud-templates/create-cloud-template.sh --vmid 9999 --help

# Quick validation test (doesn't create anything)
./cloud-templates/create-cloud-template.sh --vmid 9999 --name test --storage local-lvm --help
```

### Verify Cluster Access (if applicable)
```bash
# Test from different nodes
for node in pve01 pve02 pve03; do
    echo "Testing $node:"
    ssh $node 'ls -la /mnt/pve/pve-nas/scripts/cloud-templates/'
    echo "---"
done
```

## 📞 Support

If you encounter issues during installation:
1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Review the main [README](../README.md)
3. Submit an issue on GitHub with your installation details

---

**Next Steps**: After installation, check out the [Cloud Templates Guide](../cloud-templates/README.md) for detailed usage instructions!
