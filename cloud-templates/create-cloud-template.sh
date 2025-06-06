#!/bin/bash

# =============================================================================
# Proxmox Cloud Template Creation Script - FINAL UPDATED VERSION
# =============================================================================
# Creates cloud-init templates for Proxmox VE clusters
# 
# RECOMMENDED STORAGE STRATEGY:
# - Templates: Store on shared storage (NFS, Ceph, etc.) for cluster access
# - VMs: Clone to local storage (local-lvm) for best performance
# - Cross-node cloning to local storage: Run clone from target node
#
# =============================================================================

set -euo pipefail

# =============================================================================
# DEFAULT CONFIGURATION
# =============================================================================

DEFAULT_VMID="9000"
DEFAULT_TEMPLATE_NAME="cloud-template"
DEFAULT_DESCRIPTION="Cloud-Init Template"
DEFAULT_MEMORY="1024"
DEFAULT_CORES="1"
DEFAULT_STORAGE="local-lvm"
DEFAULT_BRIDGE="vmbr0"
DEFAULT_IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"

# =============================================================================
# COLORS AND LOGGING
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# HELP FUNCTION
# =============================================================================

show_help() {
    cat << EOF
Proxmox Cloud Template Creation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --vmid <id>              VM ID (default: $DEFAULT_VMID)
    --name <n>            Template name (default: $DEFAULT_TEMPLATE_NAME)
    --description <desc>     Description (default: "$DEFAULT_DESCRIPTION")
    --image-url <url>        Cloud image URL
    --memory <mb>            Memory in MB (default: $DEFAULT_MEMORY)
    --cores <num>            CPU cores (default: $DEFAULT_CORES)
    --storage <storage>      Storage name (default: $DEFAULT_STORAGE)
    --bridge <bridge>        Network bridge (default: $DEFAULT_BRIDGE)
    --cleanup                Remove downloaded files (default)
    --no-cleanup             Keep downloaded files
    --force                  Overwrite existing VM/template
    --help                   Show this help

EXAMPLES:
    # Basic Debian 12 template on shared storage
    $0 --vmid 9000 --name debian-12 --storage pve-nas

    # Ubuntu 22.04 template
    $0 --vmid 9010 --name ubuntu-22 --storage pve-nas \\
       --image-url https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

CLONE EXAMPLES (after template creation):
    # Clone to local storage (same node)
    qm clone 9000 101 --name my-vm --full --storage local-lvm

    # Clone to different node's local storage (run from target node)
    ssh pve02 'qm clone 9000 102 --name my-vm --full --storage local-lvm'

    # Clone to different node with shared storage
    qm clone 9000 103 --name my-vm --target pve02 --full --storage pve-nas

EOF
}

# =============================================================================
# PARAMETER PARSING
# =============================================================================

VMID="$DEFAULT_VMID"
TEMPLATE_NAME="$DEFAULT_TEMPLATE_NAME"
DESCRIPTION="$DEFAULT_DESCRIPTION"
IMAGE_URL="$DEFAULT_IMAGE_URL"
MEMORY="$DEFAULT_MEMORY"
CORES="$DEFAULT_CORES"
STORAGE="$DEFAULT_STORAGE"
BRIDGE="$DEFAULT_BRIDGE"
CLEANUP=true
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --vmid)
            VMID="$2"
            shift 2
            ;;
        --name)
            TEMPLATE_NAME="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --image-url)
            IMAGE_URL="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cores)
            CORES="$2"
            shift 2
            ;;
        --storage)
            STORAGE="$2"
            shift 2
            ;;
        --bridge)
            BRIDGE="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_vmid() {
    if ! [[ "$VMID" =~ ^[0-9]+$ ]] || [ "$VMID" -lt 100 ] || [ "$VMID" -gt 999999999 ]; then
        log_error "Invalid VMID: $VMID (must be 100-999999999)"
        exit 1
    fi
    
    if [ "$VMID" -lt 9000 ] || [ "$VMID" -gt 9999 ]; then
        log_warning "VMID $VMID outside recommended template range (9000-9999)"
    fi
}

check_vm_exists() {
    if qm config "$VMID" > /dev/null 2>&1; then
        if [ "$FORCE" = false ]; then
            log_error "VM/Template $VMID already exists. Use --force to overwrite"
            exit 1
        else
            log_warning "Removing existing VM/Template $VMID"
            qm destroy "$VMID" --purge
            sleep 2
        fi
    fi
}

check_storage() {
    if ! pvesm status -storage "$STORAGE" > /dev/null 2>&1; then
        log_error "Storage '$STORAGE' not found"
        log_info "Available storage:"
        pvesm status
        exit 1
    fi
    
    # Check if shared storage
    local storage_type
    storage_type=$(pvesm status -storage "$STORAGE" | awk 'NR==2 {print $2}')
    
    case "$storage_type" in
        "nfs"|"ceph"|"iscsi"|"glusterfs")
            log_success "Using shared storage '$STORAGE' ($storage_type) - cluster accessible"
            ;;
        "dir"|"local"|"lvm")
            log_warning "Using local storage '$STORAGE' ($storage_type) - node-specific only"
            ;;
        *)
            log_info "Storage type: $storage_type"
            ;;
    esac
}

check_url() {
    log_info "Validating image URL..."
    if ! curl --head --silent --fail --connect-timeout 10 "$IMAGE_URL" > /dev/null 2>&1; then
        log_error "Cannot access URL: $IMAGE_URL"
        exit 1
    fi
}

# =============================================================================
# MAIN FUNCTIONS - COMPLETELY FIXED
# =============================================================================

download_image() {
    local filename
    local download_path
    
    filename=$(basename "$IMAGE_URL")
    download_path="/tmp/$filename"
    
    echo -e "${BLUE}[INFO]${NC} Target file: $download_path" >&2
    
    # Check if file already exists
    if [ -f "$download_path" ]; then
        local file_size
        file_size=$(du -h "$download_path" 2>/dev/null | cut -f1)
        echo -e "${YELLOW}[WARNING]${NC} File already exists: $download_path ($file_size)" >&2
        echo -n "Reuse existing file? [y/N]: " >&2
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if file "$download_path" | grep -qE "QEMU|disk image|data"; then
                echo -e "${GREEN}[SUCCESS]${NC} Reusing existing file" >&2
                echo "$download_path"
                return 0
            else
                echo -e "${YELLOW}[WARNING]${NC} File corrupted, re-downloading" >&2
                rm -f "$download_path"
            fi
        else
            echo -e "${BLUE}[INFO]${NC} Removing existing file" >&2
            rm -f "$download_path"
        fi
    fi
    
    # Download file
    echo -e "${BLUE}[INFO]${NC} Downloading: $IMAGE_URL" >&2
    if ! wget --progress=dot:giga -O "$download_path" "$IMAGE_URL" >&2; then
        echo -e "${RED}[ERROR]${NC} Download failed" >&2
        rm -f "$download_path"
        exit 1
    fi
    
    # Verify download
    if [ ! -f "$download_path" ] || [ ! -s "$download_path" ]; then
        echo -e "${RED}[ERROR]${NC} Download verification failed" >&2
        exit 1
    fi
    
    local final_size
    final_size=$(du -h "$download_path" | cut -f1)
    echo -e "${GREEN}[SUCCESS]${NC} Downloaded successfully: $final_size" >&2
    
    # Return ONLY the file path to stdout
    echo "$download_path"
}

create_vm() {
    log_info "Creating VM $VMID: '$TEMPLATE_NAME'"
    
    if ! qm create "$VMID" \
        --name "$TEMPLATE_NAME" \
        --description "$DESCRIPTION" \
        --ostype l26 \
        --memory "$MEMORY" \
        --cores "$CORES" \
        --sockets 1 \
        --cpu host \
        --net0 "virtio,bridge=$BRIDGE" \
        --serial0 socket \
        --vga std \
        --agent enabled=1; then
        log_error "Failed to create VM"
        exit 1
    fi
    
    log_success "VM created successfully"
}

import_disk() {
    local image_path="$1"
    
    # Verify file exists
    if [ ! -f "$image_path" ]; then
        log_error "Image file not found: $image_path"
        exit 1
    fi
    
    local file_size
    file_size=$(du -h "$image_path" | cut -f1)
    
    log_info "Importing disk to storage: $STORAGE"
    log_info "File: $image_path ($file_size)"
    
    # Import disk
    if ! qm importdisk "$VMID" "$image_path" "$STORAGE"; then
        log_error "Failed to import disk"
        exit 1
    fi
    
    # Find the unused disk path that was just imported
    local unused_disk_path
    unused_disk_path=$(qm config "$VMID" | grep '^unused0:' | cut -d: -f2- | sed 's/^ *//')
    
    if [ -z "$unused_disk_path" ]; then
        log_error "Could not find imported disk path in VM config"
        log_info "Current VM config:"
        qm config "$VMID"
        exit 1
    fi
    
    log_info "Found imported disk path: $unused_disk_path"
    
    # Attach the unused disk to scsi0
    if ! qm set "$VMID" --scsi0 "$unused_disk_path"; then
        log_error "Failed to attach disk $unused_disk_path"
        exit 1
    fi
    
    log_success "Disk imported and attached as scsi0"
}

configure_cloud_init() {
    log_info "Configuring cloud-init"
    
    # Add cloud-init drive
    if ! qm set "$VMID" --ide2 "$STORAGE:cloudinit"; then
        log_error "Failed to add cloud-init drive"
        exit 1
    fi
    
    # Set boot order
    if ! qm set "$VMID" --boot c --bootdisk scsi0; then
        log_error "Failed to set boot configuration"
        exit 1
    fi
    
    log_success "Cloud-init configured"
}

convert_to_template() {
    log_info "Converting VM to template"
    
    if ! qm template "$VMID"; then
        log_error "Failed to convert to template"
        exit 1
    fi
    
    # Check for NFS chattr warning (this is normal and not an error)
    if [[ "$STORAGE" == *"nfs"* ]] || pvesm status -storage "$STORAGE" | grep -q "nfs"; then
        log_warning "NFS chattr warning is normal - template created successfully"
    fi
    
    log_success "Template conversion complete"
}

show_results() {
    echo ""
    log_success "=== TEMPLATE READY ==="
    log_success "Template '$TEMPLATE_NAME' (ID: $VMID) created successfully!"
    echo ""
    
    echo "Template Configuration:"
    echo "======================"
    qm config "$VMID"
    echo ""
    
    echo "Usage Examples:"
    echo "==============="
    echo "# Clone template to local storage (same node):"
    echo "qm clone $VMID 101 --name my-vm --full --storage local-lvm"
    echo ""
    echo "# Clone to different node's local storage (run from target node):"
    echo "ssh pve02 'qm clone $VMID 102 --name my-vm --full --storage local-lvm'"
    echo ""
    echo "# Clone to different node with shared storage:"
    echo "qm clone $VMID 103 --name my-vm --target pve02 --full --storage pve-nas"
    echo ""
    echo "# Clone with cloud-init configuration (dual auth recommended):"
    echo "qm clone $VMID 104 --name web-server --full --storage local-lvm"
    echo "qm set 104 --ciuser ansible --cipassword pass123 --sshkeys /root/.ssh/id_rsa.pub --ipconfig0 ip=dhcp"
    echo "qm start 104"
    echo ""
    echo "# Console access (VGA configured):"
    echo "qm terminal 104"
    echo ""
    echo "# SSH access:"
    echo "ssh ansible@<vm-ip>"
    echo ""
    
    # Check storage type for cluster info
    local storage_type
    storage_type=$(pvesm status -storage "$STORAGE" | awk 'NR==2 {print $2}')
    case "$storage_type" in
        "nfs"|"ceph"|"iscsi"|"glusterfs")
            log_success "Template is on shared storage - accessible from all cluster nodes!"
            echo ""
            echo "Cluster Notes:"
            echo "============="
            echo "• Template accessible from any node"
            echo "• Console access: qm terminal $VMID (from any node)"
            echo "• For local storage VMs: run clone from target node"
            echo "• For shared storage VMs: can clone from any node"
            ;;
        *)
            log_warning "Template is on local storage - only accessible from this node"
            echo ""
            echo "Console access: qm terminal $VMID"
            ;;
    esac
}

cleanup_files() {
    if [ "$CLEANUP" = true ] && [ -n "${1:-}" ] && [ -f "$1" ]; then
        log_info "Cleaning up downloaded file: $(basename "$1")"
        rm -f "$1"
        log_success "Cleanup complete"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "=== Proxmox Cloud Template Creation ==="
    log_info "Template: $TEMPLATE_NAME (ID: $VMID)"
    log_info "Storage: $STORAGE"
    log_info "Resources: ${MEMORY}MB RAM, ${CORES} cores"
    echo ""
    
    # Validation phase
    log_info "=== VALIDATION PHASE ==="
    validate_vmid
    check_vm_exists
    check_storage
    check_url
    log_success "All validations passed"
    echo ""
    
    # Creation phase
    log_info "=== CREATION PHASE ==="
    
    # Download image
    log_info "Step 1: Download cloud image"
    DOWNLOADED_IMAGE=$(download_image)
    
    # Create VM
    log_info "Step 2: Create VM"
    create_vm
    
    # Import disk
    log_info "Step 3: Import disk"
    import_disk "$DOWNLOADED_IMAGE"
    
    # Configure cloud-init
    log_info "Step 4: Configure cloud-init"
    configure_cloud_init
    
    # Convert to template
    log_info "Step 5: Convert to template"
    convert_to_template
    
    # Show results
    show_results
    
    # Cleanup
    cleanup_files "$DOWNLOADED_IMAGE"
    
    echo ""
    log_success "=== TEMPLATE CREATION COMPLETED SUCCESSFULLY ==="
}

# =============================================================================
# PREREQUISITES CHECK
# =============================================================================

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi

# Check required commands
for cmd in qm wget curl pvesm; do
    if ! command -v "$cmd" > /dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

# Run main function
main "$@"