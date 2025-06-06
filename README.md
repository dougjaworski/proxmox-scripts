# Proxmox Scripts

Proxmox cloud template creation and VM bootstrap automation. Create optimized templates with VGA console access and deploy VMs with automated cloud-init configurations.

## 📁 Repository Structure

```
proxmox-scripts/
├── cloud-templates/          # Template creation scripts
│   ├── README.md            # Detailed template creation guide
│   └── create-cloud-template.sh # Main template creation script
└── cloud-init/              # Bootstrap configurations for VMs
    ├── README.md            # Setup and usage guide
    ├── basic-bootstrap.yml   # Essential server setup
    └── enhanced-bootstrap.yml # Development/production ready
```

## 🎯 What This Repository Provides

### 1. **Template Creation** (`cloud-templates/`)

Create optimized Proxmox VM templates with VGA console access from cloud images.

- **Automated downloads** of Debian, Ubuntu, Rocky Linux cloud images
- **VGA console configuration** for perfect `qm terminal` access
- **Cloud-init ready** templates for automation
- **Cluster-aware** storage recommendations

### 2. **VM Bootstrap** (`cloud-init/`)

Ready-to-use cloud-init configurations for automated server setup.

- **User setup** with SSH keys and passwordless sudo
- **Essential tools** and QEMU guest agent
- **Security hardening** with firewall configuration
- **Development tools** (Docker, Python, Node.js) in enhanced version

## 🚀 Complete Setup Workflow

### Step 1: Clone Repository on Proxmox Server

You can clone this repository to any location that works for your setup:

#### Option A: Clone to /opt (Local Storage)

```bash
# Clone to local /opt directory
cd /opt
git clone https://github.com/dougjaworski/proxmox-scripts.git
cd proxmox-scripts

# Make scripts executable
chmod +x cloud-templates/*.sh
```

#### Option B: Clone to NAS/Shared Storage (Recommended for Clusters)

```bash
# First, check what storage/NAS is mounted
df -h
# Or view Proxmox storage
pvesm status

# Example: Clone to NFS share
cd /mnt/pve/your-nas-name
git clone https://github.com/dougjaworski/proxmox-scripts.git
cd proxmox-scripts

# Make scripts executable
chmod +x cloud-templates/*.sh
```

#### Viewing Your NAS/Storage Options

```bash
# View all mounted storage
df -h | grep -E "(mnt|pve)"

# View Proxmox configured storage
pvesm status

# List contents of a specific NAS/storage
ls -la /mnt/pve/
# Example output might show: pve-nas, shared-storage, backup-storage, etc.

# Choose your preferred location and clone there
cd /mnt/pve/your-preferred-storage
git clone https://github.com/dougjaworski/proxmox-scripts.git
```

### Step 2: Create Templates

```bash
# Navigate to your repository location
cd /your/repository/location/proxmox-scripts

# Create a Debian 12 template with VGA console
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "local-lvm"
```

### Step 3: Install Cloud-Init Files

```bash
# From your repository location, copy cloud-init files to snippets storage
cp /your/repository/location/proxmox-scripts/cloud-init/*.yml /var/lib/vz/snippets/

# For shared storage (if using)
# cp /your/repository/location/proxmox-scripts/cloud-init/*.yml /mnt/pve/your-shared-storage/snippets/

# Set proper permissions
chmod 644 /var/lib/vz/snippets/*.yml
```

### Step 4: Enable Snippets Content Type

Ensure your storage supports snippets:

```bash
# Add snippets content type to local storage
pvesm set local -content backup,vztmpl,iso,snippets

# Verify it worked
pvesm status -storage local
```

### Step 5: Deploy VMs with Cloud-Init

```bash
# Clone template
qm clone 9000 101 --name "my-server" --full --storage local-lvm

# Configure with cloud-init
qm set 101 \
  --ciuser admin \
  --cipassword "changeme123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --cicustom "user=local:snippets/basic-bootstrap.yml"

# Start the VM
qm start 101
```

### Step 6: Access Your Server

```bash
# Perfect console access (VGA optimized)
qm terminal 101

# SSH with your configured keys
ssh admin@<server-ip>

# Check bootstrap status
server-status
```

## 📖 Documentation

### **[Template Creation Guide](cloud-templates/README.md)**

- Comprehensive template creation documentation
- Storage strategies and cluster deployment
- Console configuration and troubleshooting

### **[Cloud-Init Setup Guide](cloud-init/README.md)**

- Detailed setup and usage instructions
- VM deployment examples
- SSH key setup and customization

## 🔧 Installation

### Clone Repository to Your Preferred Location

You have flexibility in where to store the repository:

- **Local storage** (`/opt`): Good for single-node setups
- **NAS/Shared storage** (`/mnt/pve/your-nas`): Recommended for clusters, scripts accessible from all nodes
- **Any writable location**: Choose what works best for your environment

```bash
# View available storage options
df -h | grep -E "(mnt|pve)"
pvesm status

# Choose your location and clone
cd /your/preferred/location
git clone https://github.com/dougjaworski/proxmox-scripts.git
cd proxmox-scripts
chmod +x cloud-templates/*.sh
```

## 🔧 Prerequisites

- **Proxmox VE 7.0+** (tested on 8.4.0)
- **Root access** to Proxmox nodes
- **Storage with snippets support** enabled
- **Internet connectivity** for downloading cloud images

## ⚡ Key Features

### Template Creation

- ✅ **VGA Console Optimization** - Perfect `qm terminal` access
- ✅ **Multiple OS Support** - Debian, Ubuntu, Rocky Linux, AlmaLinux
- ✅ **Storage Flexibility** - Local or shared storage options
- ✅ **Cluster Aware** - Works across Proxmox cluster nodes

### Cloud-Init Bootstrap

- ✅ **User Management** - SSH keys, passwordless sudo
- ✅ **Security Hardening** - Firewall, fail2ban (enhanced version)
- ✅ **Essential Tools** - System utilities, monitoring scripts
- ✅ **Development Ready** - Docker, Python, Node.js (enhanced version)

## 📋 Quick Reference

### Common Commands

```bash
# Create template (from your repository location)
cd /your/repository/location/proxmox-scripts
./cloud-templates/create-cloud-template.sh --vmid 9000 --name debian-12

# Copy cloud-init files
cp cloud-init/*.yml /var/lib/vz/snippets/

# Clone and configure VM
qm clone 9000 101 --name my-vm --full --storage local-lvm
qm set 101 --cicustom "user=local:snippets/basic-bootstrap.yml" --ciuser admin --ipconfig0 ip=dhcp
qm start 101

# Access VM
qm terminal 101
ssh admin@<vm-ip>
```

### Cloud-Init File Locations

| Storage Type | Snippets Directory               | VM Reference                        |
| ------------ | -------------------------------- | ----------------------------------- |
| Local        | `/var/lib/vz/snippets/`          | `local:snippets/filename.yml`       |
| Shared NFS   | `/mnt/pve/nfs-storage/snippets/` | `nfs-storage:snippets/filename.yml` |

## 🎯 Use Cases

### **Homelab Automation**

- Create templates once, deploy VMs rapidly
- Consistent server configuration across environment
- Easy troubleshooting with VGA console access

### **Development Environment**

- Spin up development VMs with Docker, tools pre-installed
- SSH key automation for secure access
- Rapid deployment and testing

### **Production Deployment**

- Standardized server templates across cluster
- Automated bootstrap with security hardening
- Guest agent integration for monitoring

## 🎨 Why This Combination Works

The template creation script + cloud-init files provide:

1. **VGA Console** - Easy troubleshooting via `qm terminal`
2. **Guest Agent** - Proxmox integration for monitoring
3. **Consistent Base** - Same starting point across all VMs
4. **SSH Automation** - Key-based access out of the box
5. **Rapid Deployment** - Minutes instead of hours

## 🚨 Important Setup Notes

### Before First Use

1. **Clone repository** on Proxmox server
2. **Copy cloud-init files** to snippets storage
3. **Enable snippets content type** on your storage
4. **Update SSH keys** in the YAML files
5. **Test with one VM** before scaling

### Storage Recommendations

- **Templates**: Shared storage for cluster-wide access
- **VMs**: Local storage for best performance
- **Cloud-init files**: Snippets storage (local or shared)

## 🔮 Advanced Automation (Optional)

Once comfortable with the manual workflow, you can integrate with Infrastructure as Code tools like **Terraform** for even greater automation. The templates and cloud-init files work perfectly with automation tools.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Perfect for rapid Proxmox VM deployment with consistent configurations!** ⚡

**⭐ Star this repository if it helps automate your Proxmox environment!**
