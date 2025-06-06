# Proxmox Scripts

A collection of automation scripts for Proxmox Virtual Environment (PVE) to streamline virtualization management, template creation, and cluster operations.

## 🚀 Current Scripts

### Cloud Template Creation
- **[create-cloud-template.sh](cloud-templates/)** - Automated creation of cloud-init templates with optimized VGA console access
- Supports Debian, Ubuntu, Rocky Linux, and other cloud images
- Cluster-aware with shared/local storage detection
- Perfect console access for troubleshooting and management

## 📋 Prerequisites

- Proxmox VE 7.0 or later
- Root access to Proxmox nodes
- Internet connectivity (for downloading cloud images)
- Git installed on your Proxmox environment

## ⚡ Quick Installation

### Option 1: Shared Storage (Recommended for Clusters)

If you have shared storage (NFS, Ceph, etc.) mounted across your cluster:

```bash
# Install on shared storage (accessible from all nodes)
cd /mnt/pve/your-shared-storage  # Replace with your shared storage path
git clone https://github.com/yourusername/proxmox-scripts.git scripts
cd scripts

# Make scripts executable
chmod +x cloud-templates/*.sh

# Run from any cluster node
./cloud-templates/create-cloud-template.sh --help
```

### Option 2: Local Installation (Single Node or Per-Node)

For single node setups or when you want scripts on each node locally:

```bash
# Install to /opt directory
cd /opt
git clone https://github.com/yourusername/proxmox-scripts.git
cd proxmox-scripts

# Make scripts executable
chmod +x cloud-templates/*.sh

# Create symlink for easy access (optional)
ln -s /opt/proxmox-scripts/cloud-templates/create-cloud-template.sh /usr/local/bin/

# Run script
./cloud-templates/create-cloud-template.sh --help
```

## 🎯 Quick Start Example

Create a Debian 12 template with VGA console access:

```bash
# Navigate to scripts directory
cd /path/to/proxmox-scripts

# Create template on shared storage (cluster accessible)
./cloud-templates/create-cloud-template.sh \
  --vmid 9000 \
  --name "debian-12-template" \
  --storage "your-shared-storage" \
  --cleanup

# Clone and configure a VM
qm clone 9000 101 --name "web-server" --full --storage local-lvm
qm set 101 --ciuser ansible --cipassword "secure123" --ipconfig0 ip=dhcp
qm start 101

# Access via console (VGA configured for perfect access)
qm terminal 101
```

## 📚 Documentation

Each script directory contains detailed documentation:

- **[Cloud Templates Guide](cloud-templates/README.md)** - Comprehensive guide for template creation
- **[Installation Guide](docs/installation.md)** - Detailed installation instructions
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🏗️ Repository Structure

```
proxmox-scripts/
├── README.md                          # This file - repository overview
├── cloud-templates/
│   ├── README.md                      # Detailed cloud template documentation
│   ├── create-cloud-template.sh       # Main template creation script
│   └── examples/                      # Usage examples and batch scripts
├── docs/
│   ├── installation.md               # Detailed installation guide
│   └── troubleshooting.md            # Common issues & solutions
└── LICENSE                           # License information
```

## 🎨 Features

### Cloud Template Creation
- ✅ **Optimized VGA Console**: Perfect interactive console access via `qm terminal`
- ✅ **Cluster Support**: Shared storage detection and recommendations
- ✅ **Multiple OS Support**: Debian, Ubuntu, Rocky Linux, AlmaLinux
- ✅ **Dual Authentication**: SSH keys + password for maximum flexibility
- ✅ **Storage Strategy**: Templates on shared storage, VMs on local storage
- ✅ **Guest Agent Ready**: Configured for automation and monitoring

### Key Benefits
- **Easy Troubleshooting**: VGA console provides excellent debugging access
- **Cluster Friendly**: Works seamlessly across Proxmox clusters
- **Production Ready**: Tested on Proxmox VE 8.4.0
- **Automation Ready**: Perfect foundation for Terraform, Ansible, CI/CD

## 🚀 Usage Scenarios

### For Proxmox Clusters
1. Install scripts on shared storage
2. Create templates accessible from all nodes
3. Clone VMs to local storage for performance
4. Manage from any cluster node

### For Single Nodes
1. Install scripts locally
2. Create templates on local storage
3. Clone and manage VMs locally

### For Development
1. Rapid VM deployment with cloud-init
2. Consistent environments across team
3. Infrastructure as Code integration

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests for:
- Additional Proxmox automation scripts
- Bug fixes and improvements
- Documentation enhancements
- New features and functionality

## 📞 Support

- **Issues**: Report bugs and feature requests via GitHub Issues
- **Documentation**: Check the individual script README files
- **Community**: Share your configurations and improvements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Roadmap

Potential future additions:
- Backup automation scripts
- Network configuration utilities
- Storage management tools
- Monitoring and alerting scripts
- Cluster management utilities

---

**⭐ Star this repository if it helps you manage your Proxmox environment!**
