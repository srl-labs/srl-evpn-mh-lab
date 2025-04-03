#!/bin/bash

# EVPN Lab Verification Script
# This script checks the essential components of an EVPN deployment

# Default SR Linux credentials
SRL_USER="admin"
SRL_PASS="NokiaSrl1!"

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "sshpass is not installed. Please install it with:"
    echo "  For Ubuntu/Debian: sudo apt-get install sshpass"
    echo "  For CentOS/RHEL: sudo yum install sshpass"
    echo "  For macOS: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# Color settings for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
}

# Function to check success/failure
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $2"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $2"
        return 1
    fi
}

# Function to check warning
check_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we have access to the nodes
print_header "CHECKING NODE ACCESSIBILITY"

# List of nodes to check
nodes=("clab-evpn-mh-leaf1" "clab-evpn-mh-leaf2" "clab-evpn-mh-leaf3" "clab-evpn-mh-spine1" "clab-evpn-mh-ce1" "clab-evpn-mh-ce2")

# Check if nodes are reachable
for node in "${nodes[@]}"; do
    if ping -c 1 -W 1 $node &> /dev/null; then
        check_result 0 "Node $node is reachable"
    else
        check_result 1 "Node $node is not reachable"
    fi
done

# Verify BGP EVPN Configuration on leaf1
print_header "CHECKING BGP EVPN CONFIGURATION ON LEAF1"

# Check BGP neighbor status on leaf1
echo "Checking BGP neighbors on leaf1..."
leaf1_bgp_output=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "show network-instance default protocols bgp neighbor" 2>/dev/null)

if [[ "$leaf1_bgp_output" == *"established"* ]]; then
    check_result 0 "BGP sessions on leaf1 are established"
    echo "$leaf1_bgp_output" | grep -A2 "established"
else
    check_result 1 "Some BGP sessions on leaf1 are not established"
fi

# Check if EVPN address family is enabled on leaf1
echo "Checking if EVPN address family is enabled on leaf1..."
leaf1_evpn_output=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "info network-instance default protocols bgp" 2>/dev/null)

if [[ "$leaf1_evpn_output" == *"afi-safi evpn"* ]] && [[ "$leaf1_evpn_output" == *"admin-state enable"* ]]; then
    check_result 0 "EVPN address family is enabled on leaf1"
else
    check_result 1 "EVPN address family is not enabled or not properly configured on leaf1"
fi

# Check MAC-VRF configuration on leaf1
print_header "CHECKING MAC-VRF CONFIGURATION ON LEAF1"

echo "Checking MAC-VRF network instances on leaf1..."
leaf1_mac_vrf=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "info network-instance | grep mac-vrf" 2>/dev/null)

if [[ -n "$leaf1_mac_vrf" ]]; then
    check_result 0 "MAC-VRF network instances are configured on leaf1"
    echo "$leaf1_mac_vrf"
else
    check_result 1 "No MAC-VRF network instances are configured on leaf1"
fi

# Check VXLAN interfaces on leaf1
print_header "CHECKING VXLAN INTERFACES ON LEAF1"

echo "Checking VXLAN tunnel interfaces on leaf1..."
leaf1_vxlan=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "show tunnel-interface vxlan-interface brief" 2>/dev/null)

if [[ -n "$leaf1_vxlan" ]]; then
    check_result 0 "VXLAN interfaces are configured on leaf1"
    echo "$leaf1_vxlan"
else
    check_result 1 "No VXLAN interfaces are configured on leaf1"
fi

# Check for EVPN routes
print_header "CHECKING EVPN ROUTES ON LEAF1"

echo "Checking for EVPN IMET (Type 3) routes on leaf1..."
leaf1_imet=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "show network-instance default protocols bgp routes evpn route-type 3 summary" 2>/dev/null)

if [[ -n "$leaf1_imet" ]] && [[ "$leaf1_imet" != *"0 Inclusive Multicast Ethernet Tag routes"* ]]; then
    check_result 0 "EVPN IMET routes are present on leaf1"
    echo "$leaf1_imet"
else
    check_result 1 "No EVPN IMET routes found on leaf1"
fi

echo "Checking for EVPN MAC/IP (Type 2) routes on leaf1..."
leaf1_mac_ip=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "show network-instance default protocols bgp routes evpn route-type 2 summary" 2>/dev/null)

if [[ -n "$leaf1_mac_ip" ]] && [[ "$leaf1_mac_ip" != *"0 MAC-IP Advertisement routes"* ]]; then
    check_result 0 "EVPN MAC/IP routes are present on leaf1"
    echo "$leaf1_mac_ip"
else
    check_warning "No EVPN MAC/IP routes found on leaf1. This is expected if no hosts have sent traffic yet."
fi

# Check MAC learning and VXLAN tunnels
print_header "CHECKING MAC LEARNING AND VXLAN TUNNELS"

echo "Checking MAC table entries in MAC-VRF on leaf1..."
# First, get the MAC-VRF instance name from leaf1
mac_vrf_instance=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "info network-instance | grep mac-vrf" 2>/dev/null | awk '{print $1}' | head -1)

if [[ -n "$mac_vrf_instance" ]]; then
    leaf1_macs=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "show network-instance $mac_vrf_instance bridge-table mac-table all" 2>/dev/null)
    
    echo "MAC entries in network-instance $mac_vrf_instance on leaf1:"
    echo "$leaf1_macs"
    
    if [[ "$leaf1_macs" == *"Total Evpn Macs"*"0 Total"* ]] && [[ "$leaf1_macs" == *"Total Learnt Macs"*"0 Total"* ]]; then
        check_warning "No MAC entries found. Try generating some traffic between CE devices to populate the MAC tables."
    else
        check_result 0 "MAC entries found in the MAC-VRF instance"
    fi
else
    check_result 1 "Could not determine MAC-VRF instance name on leaf1"
fi

# Check VXLAN tunnels
echo "Checking VXLAN tunnels on leaf1..."
leaf1_vxlan_tunnels=$(sshpass -p "$SRL_PASS" ssh -o StrictHostKeyChecking=no $SRL_USER@clab-evpn-mh-leaf1 "show tunnel vxlan-tunnel all" 2>/dev/null)

if [[ -n "$leaf1_vxlan_tunnels" ]] && [[ "$leaf1_vxlan_tunnels" != *"0 VXLAN tunnels"* ]]; then
    check_result 0 "VXLAN tunnels are established on leaf1"
    echo "$leaf1_vxlan_tunnels"
else
    check_result 1 "No VXLAN tunnels are established on leaf1"
fi

# Check connectivity between CE devices
print_header "CHECKING CONNECTIVITY BETWEEN CE DEVICES"

echo "Attempting to ping from CE1 to CE2..."
ce1_to_ce2_ping=$(docker exec -it clab-evpn-mh-ce1 ping -c 4 192.168.0.2 2>/dev/null)

if [[ "$ce1_to_ce2_ping" == *"0% packet loss"* ]] || [[ "$ce1_to_ce2_ping" == *", 0% packet loss"* ]]; then
    check_result 0 "CE1 can successfully ping CE2"
    echo "$ce1_to_ce2_ping"
else
    check_result 1 "CE1 cannot ping CE2"
    echo "You may need to generate some traffic first to populate MAC tables or check your configuration"
    echo "$ce1_to_ce2_ping"
fi

# Summary
print_header "VERIFICATION SUMMARY"

echo "The EVPN verification script has completed."
echo "Check the results above to ensure that your EVPN configuration is working correctly."
echo "If you see warnings or failures, review the specific areas to troubleshoot."
echo ""
echo "Key areas to verify:"
echo "1. BGP EVPN sessions are established"
echo "2. MAC-VRF network instances are properly configured"
echo "3. VXLAN interfaces are set up correctly"
echo "4. EVPN routes (both IMET and MAC/IP) are being exchanged"
echo "5. MAC tables are populated"
echo "6. VXLAN tunnels are established"
echo "7. End-to-end connectivity between CE devices is working"