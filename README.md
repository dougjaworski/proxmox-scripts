# Proxmox Scripts

Automation tools for Proxmox Virtual Environment - from template creation to VM deployment.

## 📁 Repository Structure

```
proxmox-scripts/
├── cloud-templates/          # Template creation scripts
│   ├── README.md            # Detailed template creation guide
│   └── create-cloud-template.sh # Main template creation script
└── cloud-init/              # Bootstrap configurations for VMs
    ├── README.md            # Terraform usage examples
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

Ready-to-use cloud-init configurations for Terraform deployments.

- **User setup** with SSH keys and passwordless sudo
- **Essential tools** and QEMU guest agent
- **Security hardening** with firewall configuration
- **Development tools** (Docker, Python, Node.js) in enhanced version

## 🚀 Quick Start Workflow

### Step 1: Create Templates

```bash
# Create a Debian 12 template with VGA console
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "local-lvm"

# Creates template with optimized console access
```

### Step 2: Deploy VMs with Terraform

```hcl
resource "proxmox_vm_qemu" "server" {
  name        = "my-server"
  target_node = "pve01"
  clone       = "9000"          # Template from step 1
  full_clone  = true

  # Use cloud-init for bootstrap
  cicustom = "user=local:snippets/basic-bootstrap.yml"
  ciuser   = "admin"
  sshkeys  = file("~/.ssh/id_rsa.pub")
  ipconfig0 = "ip=dhcp"
}
```

### Step 3: Access Your Server

```bash
# Perfect console access (VGA optimized)
qm terminal <vmid>

# SSH with your configured keys
ssh admin@<server-ip>
```

## 🎯 Use Cases

### **Homelab Automation**

- Create templates once, deploy VMs rapidly
- Consistent server configuration across environment
- Easy troubleshooting with VGA console access

### **Development Environment**

- Spin up development VMs with Docker, tools pre-installed
- Terraform-managed infrastructure as code
- SSH key automation for secure access

### **Production Deployment**

- Standardized server templates across cluster
- Automated bootstrap with security hardening
- Guest agent integration for monitoring

## 📖 Documentation

### Template Creation

- **[Cloud Templates Guide](cloud-templates/README.md)** - Comprehensive template creation documentation
- Covers storage strategies, cluster deployment, console configuration
- Multiple OS examples and troubleshooting

### Cloud-Init Bootstrap

- **[Cloud-Init Guide](cloud-init/README.md)** - Terraform integration and usage examples
- Ready-to-use configurations for different server types
- SSH key setup and customization instructions

## 🛠️ Prerequisites

- **Proxmox VE 7.0+** (tested on 8.4.0)
- **Root access** to Proxmox nodes
- **Internet connectivity** for downloading cloud images
- **Terraform** (for VM deployment automation)

## ⚡ Key Features

### Template Creation

- ✅ **VGA Console Optimization** - Perfect `qm terminal` access
- ✅ **Multiple OS Support** - Debian, Ubuntu, Rocky Linux
- ✅ **Storage Flexibility** - Local or shared storage options
- ✅ **Cluster Aware** - Works across Proxmox cluster nodes

### Cloud-Init Bootstrap

- ✅ **User Management** - SSH keys, passwordless sudo
- ✅ **Security Hardening** - Firewall, fail2ban (enhanced)
- ✅ **Essential Tools** - System utilities, monitoring
- ✅ **Development Ready** - Docker, Python, Node.js (enhanced)

## 🔧 Installation

### Clone Repository

```bash
# Clone to shared storage (cluster-wide access)
cd /mnt/pve/your-shared-storage
git clone https://github.com/yourusername/proxmox-scripts.git

# Or clone locally
cd /opt
git clone https://github.com/yourusername/proxmox-scripts.git
```

### Make Scripts Executable

```bash
cd proxmox-scripts
chmod +x cloud-templates/*.sh
```

### Install Cloud-Init Files

```bash
# Copy to Proxmox snippets storage
cp cloud-init/*.yml /var/lib/vz/snippets/
# Or: cp cloud-init/*.yml /mnt/pve/your-storage/snippets/
```

## 🎨 Template + Cloud-Init Integration

The template creation script produces templates optimized for cloud-init automation:

1. **VGA Console** - Easy troubleshooting and monitoring
2. **Serial Port** - Guest agent functionality
3. **Cloud-Init Drive** - Ready for automated configuration
4. **Consistent Base** - Same starting point for all VMs

This combination provides the perfect foundation for Infrastructure as Code with Terraform.

## 🚨 Important Notes

### Before Using Cloud-Init Files

- **Update SSH keys** in the YAML files with your actual public keys
- **Review user accounts** and customize as needed
- **Adjust firewall rules** for your network environment

### Storage Strategy

- **Templates**: Shared storage for cluster-wide access
- **VMs**: Local storage for best performance
- **Cloud-init files**: Snippets storage for Terraform reference

## 📋 Common Workflows

### Basic Server Deployment

```bash
# 1. Create template
./cloud-templates/create-cloud-template.sh --vmid 9000 --name debian-12

# 2. Deploy with Terraform using basic-bootstrap.yml
# 3. SSH to server with configured keys
```

### Development Environment

```bash
# 1. Create template with more resources
./cloud-templates/create-cloud-template.sh --vmid 9001 --name dev-template --memory 4096 --cores 2

# 2. Deploy with enhanced-bootstrap.yml for Docker + dev tools
# 3. Start developing immediately
```

### Production Deployment

```bash
# 1. Create template on shared storage
./cloud-templates/create-cloud-template.sh --vmid 9000 --storage shared-storage

# 2. Deploy VMs across cluster nodes with Terraform
# 3. Automated, consistent production servers
```

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- Additional cloud-init configurations
- Support for more Linux distributions
- Enhanced automation scripts
- Documentation improvements

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Perfect for Infrastructure as Code workflows with Terraform and Proxmox!** ⚡
