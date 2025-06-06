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

#### Option A: Clone to NAS/Shared Storage (Recommended for Clusters)

```bash
# Check what NAS/shared storage is available
pvesm status
df -h | grep -E "(mnt|pve)"

# Clone to your NAS storage
cd /mnt/pve/pve-nas  # Replace 'pve-nas' with your NAS storage name
git clone https://github.com/dougjaworski/proxmox-scripts.git
cd proxmox-scripts

# Make scripts executable
chmod +x cloud-templates/*.sh
```

#### Option B: Clone to /opt (Local Storage)

```bash
# Clone to local /opt directory
cd /opt
git clone https://github.com/dougjaworski/proxmox-scripts.git
cd proxmox-scripts

# Make scripts executable
chmod +x cloud-templates/*.sh
```

### Step 2: Create Templates

```bash
# Navigate to your repository location
cd /mnt/pve/pve-nas/proxmox-scripts  # Or wherever you cloned it

# Create a Debian 12 template with VGA console
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "local-lvm"
```

### Step 3: Install Cloud-Init Files

#### Check Your Storage Setup First

```bash
# Check which storage has snippets support enabled
pvesm status

# Look for storage with 'snippets' in the content types
# Example: pve-nas might show "backup,images,snippets"
```

#### If Your NAS Already Has Snippets Support (Recommended)

```bash
# Copy cloud-init files to your NAS snippets directory
cp cloud-init/*.yml /mnt/pve/pve-nas/snippets/  # Replace 'pve-nas' with your NAS name

# Set proper permissions
chmod 644 /mnt/pve/pve-nas/snippets/*.yml

# Verify files are in place
ls -la /mnt/pve/pve-nas/snippets/*.yml
```

#### If Using Local Storage for Snippets

```bash
# Copy cloud-init files to local snippets directory
cp cloud-init/*.yml /var/lib/vz/snippets/

# Enable snippets content type on local storage
pvesm set local -content backup,vztmpl,iso,snippets

# Set proper permissions
chmod 644 /var/lib/vz/snippets/*.yml
```

#### If Your NAS Needs Snippets Enabled

```bash
# Enable snippets on your NAS storage
pvesm set pve-nas -content backup,images,snippets  # Replace 'pve-nas' with your storage name

# Verify it worked
pvesm status -storage pve-nas
```

### Step 4: Deploy VMs with Cloud-Init

#### Using NAS Storage for Cloud-Init (Cluster-Friendly)

```bash
# Clone template
qm clone 9000 101 --name "my-server" --full --storage local-lvm

# Configure with cloud-init from NAS storage
qm set 101 \
  --ciuser admin \
  --cipassword "changeme123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --cicustom "user=pve-nas:snippets/basic-bootstrap.yml"  # Reference your NAS storage

# Start the VM
qm start 101
```

#### Using Local Storage for Cloud-Init

```bash
# Clone template
qm clone 9000 102 --name "my-server-local" --full --storage local-lvm

# Configure with cloud-init from local storage
qm set 102 \
  --ciuser admin \
  --cipassword "changeme123" \
  --sshkeys /root/.ssh/id_rsa.pub \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8 \
  --cicustom "user=local:snippets/basic-bootstrap.yml"  # Reference local storage

# Start the VM
qm start 102
```

### Step 5: Access Your Server

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

- **NAS/Shared storage** (`/mnt/pve/your-nas`): Recommended for clusters, scripts accessible from all nodes
- **Local storage** (`/opt`): Good for single-node setups
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
cd /mnt/pve/pve-nas/proxmox-scripts  # Or your chosen location
./cloud-templates/create-cloud-template.sh --vmid 9000 --name debian-12

# Copy cloud-init files to NAS snippets (recommended for clusters)
cp cloud-init/*.yml /mnt/pve/pve-nas/snippets/

# OR copy to local snippets
cp cloud-init/*.yml /var/lib/vz/snippets/

# Clone and configure VM (NAS example)
qm clone 9000 101 --name my-vm --full --storage local-lvm
qm set 101 --cicustom "user=pve-nas:snippets/basic-bootstrap.yml" --ciuser admin --ipconfig0 ip=dhcp
qm start 101

# Access VM
qm terminal 101
ssh admin@<vm-ip>
```

### Cloud-Init File Locations

| Setup Type        | Snippets Directory           | VM Reference                    | Best For     |
| ----------------- | ---------------------------- | ------------------------------- | ------------ |
| **NAS Storage**   | `/mnt/pve/pve-nas/snippets/` | `pve-nas:snippets/filename.yml` | **Clusters** |
| **Local Storage** | `/var/lib/vz/snippets/`      | `local:snippets/filename.yml`   | Single nodes |

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

1. **Clone repository** on Proxmox server (NAS or local)
2. **Copy cloud-init files** to snippets storage
3. **Check snippets support** on your storage
4. **Update SSH keys** in the YAML files
5. **Test with one VM** before scaling

### Storage Recommendations

- **Templates**: Shared storage for cluster-wide access
- **VMs**: Local storage for best performance
- **Cloud-init files**: NAS snippets storage for clusters, local for single nodes

### NAS Storage Benefits (Recommended for Clusters)

- ✅ **All cluster nodes** can access the same cloud-init files
- ✅ **Centralized management** - edit once, available everywhere
- ✅ **Consistent deployments** across all nodes
- ✅ **Backed up** with your NAS backup strategy

## 🔮 Advanced Automation (Optional)

Once comfortable with the manual workflow, you can integrate with Infrastructure as Code tools like **Terraform** for even greater automation. The templates and cloud-init files work perfectly with automation tools.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Perfect for rapid Proxmox VM deployment with consistent configurations!** ⚡

**⭐ Star this repository if it helps automate your Proxmox environment!**
