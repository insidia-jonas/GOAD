#!/bin/bash
# Generate rendered inventory for GOAD deployment
# This script replaces {{ip_range}} placeholders with actual IP range
#
# Usage: ./generate_inventory.sh <ip_range> [lab_name] [provider]
# Example: ./generate_inventory.sh 10.2.10 GOAD ludus
#
# For Ludus: Your IP range is typically 10.X.10 where X is your range ID
# Check with: ludus range list

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOAD_DIR="$(dirname "$SCRIPT_DIR")"

IP_RANGE="${1:-}"
LAB_NAME="${2:-GOAD}"
PROVIDER="${3:-ludus}"

if [ -z "$IP_RANGE" ]; then
    echo "Usage: $0 <ip_range> [lab_name] [provider]"
    echo ""
    echo "Arguments:"
    echo "  ip_range   - The IP range prefix (e.g., 10.2.10, 192.168.56)"
    echo "  lab_name   - Lab name (default: GOAD)"
    echo "  provider   - Provider name (default: ludus)"
    echo ""
    echo "Examples:"
    echo "  $0 10.2.10              # Ludus with range ID 2"
    echo "  $0 192.168.56 GOAD virtualbox"
    echo ""
    echo "For Ludus users:"
    echo "  Run 'ludus range list' to find your range ID"
    echo "  Your IP range will be 10.<range_id>.10"
    exit 1
fi

TEMPLATE_DIR="$GOAD_DIR/ad/$LAB_NAME/providers/$PROVIDER"
OUTPUT_DIR="$GOAD_DIR/workspace/manual-$LAB_NAME-$PROVIDER"
INVENTORY_TEMPLATE="$TEMPLATE_DIR/inventory"
MAIN_INVENTORY="$GOAD_DIR/ad/$LAB_NAME/data/inventory"

if [ ! -f "$INVENTORY_TEMPLATE" ]; then
    echo "ERROR: Inventory template not found: $INVENTORY_TEMPLATE"
    exit 1
fi

if [ ! -f "$MAIN_INVENTORY" ]; then
    echo "ERROR: Main inventory not found: $MAIN_INVENTORY"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Generating inventory for:"
echo "  Lab:      $LAB_NAME"
echo "  Provider: $PROVIDER"
echo "  IP Range: $IP_RANGE"
echo "  Output:   $OUTPUT_DIR"
echo ""

# Generate provider inventory (replace {{ip_range}})
sed "s/{{ip_range}}/$IP_RANGE/g" "$INVENTORY_TEMPLATE" > "$OUTPUT_DIR/inventory"

# Copy main inventory (for host groups)
cp "$MAIN_INVENTORY" "$OUTPUT_DIR/lab_inventory"

echo "Generated files:"
echo "  $OUTPUT_DIR/inventory"
echo "  $OUTPUT_DIR/lab_inventory"
echo ""
echo "To run ansible playbooks, use:"
echo "  cd $GOAD_DIR/ansible"
echo "  ansible-playbook -i $OUTPUT_DIR/lab_inventory -i $OUTPUT_DIR/inventory <playbook>.yml"
echo ""
echo "Or add this alias to your shell:"
echo "  alias goad-ansible='ansible-playbook -i $OUTPUT_DIR/lab_inventory -i $OUTPUT_DIR/inventory'"
