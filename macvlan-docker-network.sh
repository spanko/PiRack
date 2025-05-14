```bash
# filepath: create-macvlan.sh
#!/usr/bin/env bash

# Usage: ./create-macvlan.sh <vlan_id>
# Example: ./create-macvlan.sh 10

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vlan_id>"
  echo "VLAN ID must be one of 10, 20, 30, 40, or 50."
  exit 1
fi

VLAN_ID="$1"

# Validate the VLAN ID
case "$VLAN_ID" in
  10|20|30|40|50) ;;
  *) echo "Error: VLAN ID must be one of 10, 20, 30, 40, or 50." >&2
     exit 1
     ;;
esac

# Build the network configuration based on VLAN ID
# This CIDR creates a range from .32 to .63 for the IP range
NETWORK_CIDR="192.168.${VLAN_ID}.0/24"
IP_RANGE_CIDR="192.168.${VLAN_ID}.32/27"
GATEWAY_IP="192.168.${VLAN_ID}.1"
PARENT_INTERFACE_NAME="eth0"  # Should probably parameterize this too...
NETWORK_NAME="docker_${VLAN_ID}"

echo "Creating Docker macvlan for VLAN ${VLAN_ID}..."
echo "  Subnet:       ${NETWORK_CIDR}"
echo "  IP Range:     ${IP_RANGE_CIDR}"
echo "  Gateway:      ${GATEWAY_IP}"
echo "  Parent Iface: ${PARENT_INTERFACE_NAME}"
echo "  Network Name: ${NETWORK_NAME}"
echo

docker network create -d macvlan \
  --subnet="${NETWORK_CIDR}" \
  --ip-range="${IP_RANGE_CIDR}" \
  --gateway="${GATEWAY_IP}" \
  --aux-address="${HOSTNAME}=${IP_RANGE_CIDR%/*}" \
  -o parent="${PARENT_INTERFACE_NAME}" "${NETWORK_NAME}"

echo "Creating local macvlan shim interface for host routing..."
ip link add macvlan-shim link "${PARENT_INTERFACE_NAME}" type macvlan mode bridge

# Give the shim interface the same address as the start of the IP range, but /32
ip addr add "${IP_RANGE_CIDR%/*}/32" dev macvlan-shim
ip link set macvlan-shim up

# Route traffic for the IP range through the shim interface
ip route add "${IP_RANGE_CIDR}" dev macvlan-shim

echo "Done. The Docker macvlan network '${NETWORK_NAME}' is now set up."
```
