#!/bin/bash

# =============================================================================
# Batch Template Creation Script for Proxmox
# =============================================================================
# Creates multiple cloud-init templates with VGA console access
# Run this script from the proxmox-scripts directory
#
# Usage: ./examples/batch-create-templates.sh [storage-name]
# Example: ./examples/batch-create-templates.sh pve-nas
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Default storage (override with command line argument)
STORAGE="${1:-local-lvm}"

# Script path (relative to this script location)
SCRIPT_PATH="../create-cloud-template.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================================================
# TEMPLATE DEFINITIONS
# =============================================================================

# Format: "VMID:NAME:DESCRIPTION:IMAGE_URL"
templates=(
    "9000:debian-12:Debian 12 Bookworm Cloud Template:https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
    "9010:ubuntu-24:Ubuntu 24.04 LTS Noble Cloud Template:https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    "9011:ubuntu-22:Ubuntu 22.04 LTS Jammy Cloud Template:https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    "9020:rocky-9:Rocky Linux 9 Cloud Template:https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
    "9021:alma-9:AlmaLinux 9 Cloud Template:https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
)

# =============================================================================
# FUNCTIONS
# =============================================================================

show_help() {
    cat << EOF
Batch Template Creation Script for Proxmox

USAGE:
    $0 [storage-name]

ARGUMENTS:
    storage-name    Storage to create templates on (default: local-lvm)

EXAMPLES:
    # Create templates on shared storage
    $0 pve-nas

    # Create templates on local storage
    $0 local-lvm

    # Use default storage
    $0

TEMPLATES CREATED:
    9000 - Debian 12 Bookworm
    9010 - Ubuntu 24.04 LTS Noble
    9011 - Ubuntu 22.04 LTS Jammy
    9020 - Rocky Linux 9
    9021 - AlmaLinux 9

All templates are created with:
    ✓ VGA console access for easy troubleshooting
    ✓ Serial port for guest agent functionality
    ✓ Cloud-init ready for automation
    ✓ 1GB RAM, 1 CPU core (easily adjustable after creation)

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Check script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        log_error "Template creation script not found: $SCRIPT_PATH"
        log_info "Make sure you're running this from the proxmox-scripts directory"
        exit 1
    fi
    
    # Check script is executable
    if [ ! -x "$SCRIPT_PATH" ]; then
        log_warning "Making script executable..."
        chmod +x "$SCRIPT_PATH"
    fi
    
    # Check storage exists
    if ! pvesm status -storage "$STORAGE" > /dev/null 2>&1; then
        log_error "Storage '$STORAGE' not found"
        log_info "Available storage:"
        pvesm status
        exit 1
    fi
    
    log_success "All prerequisites met"
}

check_existing_templates() {
    log_info "Checking for existing templates..."
    
    local conflicts=()
    
    for template in "${templates[@]}"; do
        IFS=':' read -r vmid name description url <<< "$template"
        
        if qm config "$vmid" > /dev/null 2>&1; then
            conflicts+=("$vmid:$name")
        fi
    done
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        log_warning "Found existing VMs/templates with conflicting IDs:"
        for conflict in "${conflicts[@]}"; do
            IFS=':' read -r vmid name <<< "$conflict"
            echo "  - VM/Template $vmid ($name)"
        done
        echo ""
        echo -n "Continue and overwrite existing templates? [y/N]: "
        read -r response
        
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            exit 0
        fi
        
        FORCE_FLAG="--force"
    else
        log_success "No conflicting templates found"
        FORCE_FLAG=""
    fi
}

create_template() {
    local vmid="$1"
    local name="$2"
    local description="$3"
    local url="$4"
    
    log_info "Creating template: $name (ID: $vmid)"
    
    # Run the template creation script
    if "$SCRIPT_PATH" \
        --vmid "$vmid" \
        --name "$name-template" \
        --description "$description with VGA Console" \
        --storage "$STORAGE" \
        --image-url "$url" \
        --cleanup \
        $FORCE_FLAG; then
        
        log_success "Template $name completed successfully"
        return 0
    else
        log_error "Template $name failed"
        return 1
    fi
}

show_summary() {
    echo ""
    log_success "=== BATCH TEMPLATE CREATION COMPLETED ==="
    echo ""
    
    echo "Created Templates:"
    echo "=================="
    
    for template in "${templates[@]}"; do
        IFS=':' read -r vmid name description url <<< "$template"
        
        if qm config "$vmid" > /dev/null 2>&1; then
            local status
            status=$(qm status "$vmid" | awk '{print $2}')
            echo "✓ $vmid - $name-template ($status)"
        else
            echo "✗ $vmid - $name-template (failed)"
        fi
    done
    
    echo ""
    echo "Storage: $STORAGE"
    
    # Check if shared storage
    local storage_type
    storage_type=$(pvesm status -storage "$STORAGE" | awk 'NR==2 {print $2}')
    
    case "$storage_type" in
        "nfs"|"ceph"|"iscsi"|"glusterfs")
            log_success "Templates are on shared storage - accessible from all cluster nodes!"
            ;;
        *)
            log_warning "Templates are on local storage - only accessible from this node"
            ;;
    esac
    
    echo ""
    echo "Usage Examples:"
    echo "==============="
    echo "# Clone template to local storage (recommended for VMs)"
    echo "qm clone 9000 101 --name my-debian-vm --full --storage local-lvm"
    echo ""
    echo "# Configure with cloud-init (dual authentication)"
    echo "qm set 101 --ciuser ansible --cipassword secure123 --sshkeys /root/.ssh/id_rsa.pub --ipconfig0 ip=dhcp"
    echo ""
    echo "# Start VM"
    echo "qm start 101"
    echo ""
    echo "# Access via console (VGA configured for perfect access)"
    echo "qm terminal 101"
    echo ""
    echo "# Cross-node deployment (if shared storage)"
    if [[ "$storage_type" =~ ^(nfs|ceph|iscsi|glusterfs)$ ]]; then
        echo "ssh pve02 'qm clone 9000 102 --name node2-vm --full --storage local-lvm'"
    fi
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Handle help request
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    echo ""
    log_info "=== Proxmox Batch Template Creation ==="
    log_info "Storage: $STORAGE"
    log_info "Templates to create: ${#templates[@]}"
    echo ""
    
    # Prerequisites and validation
    check_prerequisites
    check_existing_templates
    
    echo ""
    log_info "=== STARTING TEMPLATE CREATION ==="
    echo ""
    
    # Create templates
    local success_count=0
    local total_count=${#templates[@]}
    
    for template in "${templates[@]}"; do
        IFS=':' read -r vmid name description url <<< "$template"
        
        echo "----------------------------------------"
        if create_template "$vmid" "$name" "$description" "$url"; then
            ((success_count++))
        fi
        echo ""
    done
    
    # Show final summary
    echo "========================================"
    show_summary
    
    # Final status
    if [ $success_count -eq $total_count ]; then
        log_success "All $total_count templates created successfully!"
        exit 0
    else
        log_warning "$success_count of $total_count templates created successfully"
        log_error "$((total_count - success_count)) templates failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
