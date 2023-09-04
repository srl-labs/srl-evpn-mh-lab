#  L2 EVPN Multi-homing Lab

This lab gives you a pre-configured SR Linux-based fabric to experiment L2 EVPN multi-homing. 

# Topology

The topology comprises a spine, three leaf(PEs) routers, and two Alpine Linux hosts(CEs). A multi-homed CE is connected to leaf1, while another is linked to leaf3 for testing purposes.

<p align="center">
<img src="images/fabric-topo.drawio.svg" width="600" alt="EVPN multi-homing lab topology" title="EVPN multi-homing lab topology" class="caption" />
</p>

## Lab deployment

As usual, this lab is powered by containerlab and can be deployed on any Linux VM with enough resources mentioned in the table at the beginning.

This lab comes with pre-configurations that are explained in [L2 EVPN tutorial](https://learn.srlinux.dev/tutorials/l2evpn/evpn/#mac-vrf), which is highly recommended if you haven't played with SR Linux or EVPN yet.

The topology and pre-configurations are defined in the containerlab topology file.

The SR Linux configurations are referred to as [config files](configs) (.cfg), and Alpine Linux configurations are defined in the [topology file](evpn-mh.clab.yml) to be directly executed at the deployment.

The SR Linux configurations are under the 'configs' folder.

Clone this repository to your Linux machine:

```bash
git clone https://github.com/srl-labs/srl-evpn-mh-lab.git && cd srl-evpn-mh-lab
```

and deploy with containerlab:

```bash
# containerlab deploy -t evpn-mh01.clab.yml
[root@clab-vm1 evpn-mh01]# containerlab deploy
INFO[0000] Containerlab v0.44.0 started
INFO[0000] Parsing & checking topology file: evpn-mh01.clab.yml
INFO[0000] Creating docker network: Name="clab", IPv4Subnet="172.20.20.0/24", IPv6Subnet="2001:172:20:20::/64", MTU="1500"
WARN[0000] Unable to load kernel module "ip_tables" automatically "load ip_tables failed: exec format error"
INFO[0000] Creating lab directory: /root/demo/learn.srlinux/clab/evpn-mh01/clab-evpn-mh01
WARN[0000] SSH_AUTH_SOCK not set, skipping pubkey fetching
INFO[0000] Creating container: "ce2"
INFO[0000] Creating container: "ce1"
INFO[0000] Creating container: "spine1"
INFO[0000] Creating container: "leaf3"
INFO[0000] Creating container: "leaf1"
INFO[0000] Creating container: "leaf2"
INFO[0003] Creating link: leaf1:e1-49 <--> spine1:e1-1
INFO[0003] Creating link: ce1:eth1 <--> leaf1:e1-1
INFO[0003] Creating link: leaf3:e1-49 <--> spine1:e1-3
INFO[0003] Creating link: leaf2:e1-49 <--> spine1:e1-2
INFO[0003] Creating link: ce2:eth1 <--> leaf3:e1-1
INFO[0003] Creating link: ce1:eth2 <--> leaf2:e1-1
INFO[0004] Creating link: ce2:eth2 <--> leaf3:e1-2
INFO[0004] Creating link: ce2:eth3 <--> leaf3:e1-3
INFO[0004] Running postdeploy actions for Nokia SR Linux 'leaf3' node
INFO[0004] Running postdeploy actions for Nokia SR Linux 'leaf1' node
INFO[0004] Running postdeploy actions for Nokia SR Linux 'spine1' node
INFO[0004] Running postdeploy actions for Nokia SR Linux 'leaf2' node
INFO[0025] Adding containerlab host entries to /etc/hosts file
INFO[0026] Executed command "ip link add bond0 type bond mode 802.3ad" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set address 00:c1:ab:00:00:11 dev bond0" on the node "ce1". stdout:
INFO[0026] Executed command "ip addr add 192.168.0.11/24 dev bond0" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set eth1 down" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set eth2 down" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set eth1 master bond0" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set eth2 master bond0" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set eth1 up" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set eth2 up" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set bond0 up" on the node "ce1". stdout:
INFO[0026] Executed command "ip link set address 00:c1:ab:00:00:21 dev eth1" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set address 00:c1:ab:00:00:22 dev eth2" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set address 00:c1:ab:00:00:23 dev eth3" on the node "ce2". stdout:
INFO[0026] Executed command "ip link add dev vrf-1 type vrf table 1" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set dev vrf-1 up" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set dev eth1 master vrf-1" on the node "ce2". stdout:
INFO[0026] Executed command "ip link add dev vrf-2 type vrf table 2" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set dev vrf-2 up" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set dev eth2 master vrf-2" on the node "ce2". stdout:
INFO[0026] Executed command "ip link add dev vrf-3 type vrf table 3" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set dev vrf-3 up" on the node "ce2". stdout:
INFO[0026] Executed command "ip link set dev eth3 master vrf-3" on the node "ce2". stdout:
INFO[0026] Executed command "ip addr add 192.168.0.21/24 dev eth1" on the node "ce2". stdout:
INFO[0026] Executed command "ip addr add 192.168.0.22/24 dev eth2" on the node "ce2". stdout:
INFO[0026] Executed command "ip addr add 192.168.0.23/24 dev eth3" on the node "ce2". stdout:
+---+-----------------------+--------------+------------------------------+-------+---------+----------------+----------------------+
| # |         Name          | Container ID |            Image             | Kind  |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------------+--------------+------------------------------+-------+---------+----------------+----------------------+
| 1 | clab-evpn-mh01-ce1    | 11d8ad808671 | akpinar/alpine:latest        | linux | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
| 2 | clab-evpn-mh01-ce2    | f563402d339f | akpinar/alpine:latest        | linux | running | 172.20.20.7/24 | 2001:172:20:20::7/64 |
| 3 | clab-evpn-mh01-leaf1  | dfcf20665a6a | ghcr.io/nokia/srlinux:23.3.1 | srl   | running | 172.20.20.4/24 | 2001:172:20:20::4/64 |
| 4 | clab-evpn-mh01-leaf2  | fee169425f04 | ghcr.io/nokia/srlinux:23.3.1 | srl   | running | 172.20.20.6/24 | 2001:172:20:20::6/64 |
| 5 | clab-evpn-mh01-leaf3  | 115bbac271c9 | ghcr.io/nokia/srlinux:23.3.1 | srl   | running | 172.20.20.5/24 | 2001:172:20:20::5/64 |
| 6 | clab-evpn-mh01-spine1 | d825b06fe483 | ghcr.io/nokia/srlinux:23.3.1 | srl   | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
+---+-----------------------+--------------+------------------------------+-------+---------+----------------+----------------------+
```

A few seconds later containerlab finishes the deployment with providing a summary table that outlines connection details of the deployed nodes. In the "Name" column we have the names of the deployed containers and those names can be used to reach the nodes, for example to connect to the SSH of `leaf1`:

```bash
# default credentials admin:NokiaSrl1!
ssh admin@clab-evpn01-leaf1
```

To connect Alpine Linux (CEs):

```bash
docker exec -it clab-evpn-mh01-ce1 bash
```


Please follow the tutorial to explore L2 EVPN Multi-homing further...
