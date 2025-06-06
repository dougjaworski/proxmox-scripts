# Troubleshooting Guide

Common issues and solutions for Proxmox Scripts, particularly the cloud template creation script.

## 🔍 Quick Diagnostics

### Script Health Check
```bash
# Navigate to scripts directory
cd /path/to/proxmox-scripts

# Check script permissions
ls -la cloud-templates/create-cloud-template.sh

# Should show: -rwxr-xr-x (executable)
# If not: chmod +x cloud-templates/create-cloud-template.sh

# Test basic functionality
./cloud-templates/create-cloud-template.sh --help
```

### System Prerequisites Check
```bash
# Check required commands
for cmd in qm wget curl pvesm; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✓ $cmd found"
    else
        echo "✗ $cmd missing"
    fi
done

# Check Proxmox version
pveversion

# Check root access
id
# Should show: uid=0(root)
```

## 🚨 Common Issues

### 1. Permission Denied Errors

**Problem**: `Permission denied` when running scripts

**Symptoms**:
```bash
./create-cloud-template.sh: Permission denied
```

**Solutions**:
```bash
# Fix script permissions
chmod +x cloud-templates/create-cloud-template.sh

# Check if running as root
sudo ./cloud-templates/create-cloud-template.sh --help

# Fix ownership if needed
chown root:root cloud-templates/create-cloud-template.sh
```

### 2. Storage Not Found

**Problem**: `Storage 'storage-name' not found`

**Symptoms**:
```bash
[ERROR] Storage 'pve-nas' not found
```

**Solutions**:
```bash
# List available storage
pvesm status

# Check storage accessibility
pvesm status -storage your-storage-name

# Test storage write access
touch /mnt/pve/your-storage/test-file && rm /mnt/pve/your-storage/test-file

# Use different storage
./create-cloud-template.sh --storage local-lvm --vmid 9000 --name test
```

### 3. VM ID Already Exists

**Problem**: VM with specified ID already exists

**Symptoms**:
```bash
[ERROR] VM/Template 9000 already exists. Use --force to overwrite
```

**Solutions**:
```bash
# Check existing VMs
qm list

# Use different VM ID
./create-cloud-template.sh --vmid 9001 --name my-template

# Or force overwrite (careful!)
./create-cloud-template.sh --vmid 9000 --name my-template --force

# Remove existing VM manually
qm destroy 9000 --purge
```

### 4. Download Failures

**Problem**: Cannot download cloud images

**Symptoms**:
```bash
[ERROR] Cannot access URL: https://cloud.debian.org/images/...
[ERROR] Download failed
```

**Solutions**:
```bash
# Test internet connectivity
ping google.com

# Test specific URL
curl -I https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Check DNS resolution
nslookup cloud.debian.org

# Use alternative image URL
./create-cloud-template.sh \
  --image-url "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" \
  --vmid 9000 --name ubuntu-test

# Download manually if needed
cd /tmp
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
# Then script will detect existing file
```

### 5. Disk Import Failures

**Problem**: Disk import fails during template creation

**Symptoms**:
```bash
[ERROR] Failed to import disk
[ERROR] Could not find imported disk path in VM config
```

**Solutions**:
```bash
# Check available storage space
df -h
pvesm status -storage your-storage

# Verify image file integrity
file /tmp/downloaded-image.qcow2
# Should show: QEMU QCOW2 Image

# Check VM configuration after creation
qm config 9000

# Manual disk import (debugging)
qm importdisk 9000 /tmp/image.qcow2 your-storage
qm config 9000  # Check for unused0: entry

# Clean up and retry
qm destroy 9000 --purge
./create-cloud-template.sh --vmid 9000 --name test --force
```

### 6. Console Access Issues

**Problem**: Console doesn't work properly after template creation

**Symptoms**:
- Black screen in console
- "starting serial terminal" messages
- Cannot interact with console

**Solutions**:
```bash
# Verify VGA configuration (script should set this correctly)
qm config 9000 | grep vga
# Should show: vga: std

# Check serial configuration
qm config 9000 | grep serial
# Should show: serial0: socket

# Fix VGA if needed
qm set 9000 --vga std

# Test console access
qm terminal 9000

# Alternative: Use web console
# Proxmox Web UI > VM > Console > noVNC
```

### 7. Cloud-Init Configuration Issues

**Problem**: Cloud-init not working in cloned VMs

**Symptoms**:
- Cannot login to VM
- Network not configured
- SSH keys not working

**Solutions**:
```bash
# Check cloud-init configuration in template
qm config 9000 | grep ide2
# Should show: ide2: storage:cloudinit

# Verify cloud-init in cloned VM
qm clone 9000 101 --name test-vm --full --storage local-lvm

# Configure cloud-init properly
qm set 101 \
  --ciuser ansible \
  --cipassword "secure123" \
  --ipconfig0 ip=dhcp \
  --nameserver 8.8.8.8

# Start and check via console
qm start 101
qm terminal 101

# Inside VM, check cloud-init status
sudo cloud-init status
sudo cloud-init logs
```

### 8. Cluster Access Issues

**Problem**: Scripts not accessible from all cluster nodes

**Symptoms**:
- Script works on one node but not others
- "No such file or directory" on other nodes

**Solutions**:
```bash
# Check shared storage mounting on all nodes
for node in pve01 pve02 pve03; do
    echo "Checking $node:"
    ssh $node 'ls -la /mnt/pve/pve-nas/scripts/' || echo "Mount issue on $node"
done

# Verify storage is shared type
pvesm status -storage pve-nas
# Type should be: nfs, ceph, glusterfs, etc.

# Check network connectivity between nodes
for node in pve02 pve03; do
    ping -c 2 $node
done

# Install scripts locally if shared storage unavailable
ssh pve02 'cd /opt && git clone https://github.com/your-repo/proxmox-scripts.git'
```

## 🔧 Advanced Troubleshooting

### Debug Mode
```bash
# Run script with full debug output
bash -x ./cloud-templates/create-cloud-template.sh --vmid 9999 --name debug-test

# Check each step individually
./cloud-templates/create-cloud-template.sh --vmid 9999 --name debug-test --no-cleanup
# This keeps downloaded files for inspection
```

### Manual Template Creation (for debugging)
```bash
# Follow script steps manually to identify issues

# 1. Download image
cd /tmp
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# 2. Create VM
qm create 9999 \
  --name debug-template \
  --ostype l26 \
  --memory 1024 \
  --cores 1 \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --vga std \
  --agent enabled=1

# 3. Import disk
qm importdisk 9999 debian-12-generic-amd64.qcow2 local-lvm

# 4. Check what happened
qm config 9999

# 5. Attach disk
qm set 9999 --scsi0 local-lvm:vm-9999-disk-0

# 6. Add cloud-init
qm set 9999 --ide2 local-lvm:cloudinit
qm set 9999 --boot c --bootdisk scsi0

# 7. Convert to template
qm template 9999
```

### Log Analysis
```bash
# Check Proxmox task logs
tail -f /var/log/pve/tasks/active

# Check system logs
journalctl -f -u pveproxy
journalctl -f -u pvedaemon

# Check VM-specific logs
tail -f /var/log/qemu-kvm/9000.log
```

## 🆘 Emergency Recovery

### Template Corruption
```bash
# If template becomes corrupted
qm destroy 9000 --purge

# Recreate from scratch
./create-cloud-template.sh --vmid 9000 --name recovery-template --force
```

### Storage Issues
```bash
# If shared storage becomes unavailable
# 1. Switch to local storage temporarily
./create-cloud-template.sh --vmid 9000 --name temp-template --storage local-lvm

# 2. Or install scripts locally
cd /opt
git clone https://github.com/your-repo/proxmox-scripts.git
```

### Cluster Communication Issues
```bash
# Check cluster status
pvecm status

# Check network connectivity
for node in pve01 pve02 pve03; do
    ssh $node 'hostname; date'
done

# Restart cluster services if needed
systemctl restart pve-cluster
systemctl restart pvedaemon
```

## 📞 Getting Help

### Information to Collect
When reporting issues, please include:

```bash
# System information
pveversion
uname -a
df -h

# Script information
ls -la cloud-templates/create-cloud-template.sh
head -20 cloud-templates/create-cloud-template.sh

# Storage information
pvesm status

# Network information
ip addr show
ping -c 2 google.com

# Error logs
./create-cloud-template.sh --vmid 9999 --name debug 2>&1 | tee debug.log
```

### Common Solutions Summary

| Issue | Quick Fix |
|-------|-----------|
| Permission denied | `chmod +x script.sh` |
| Storage not found | `pvesm status` and use correct storage name |
| VM ID exists | Use `--force` or different `--vmid` |
| Download fails | Check internet connectivity |
| Console issues | Verify `--vga std` in VM config |
| Cloud-init problems | Check cloud-init drive and user config |
| Cluster access | Verify shared storage mounting |

---

**Still having issues?** 
1. Check the [Installation Guide](installation.md)
2. Review the [Main README](../README.md)
3. Submit a GitHub issue with debug information
