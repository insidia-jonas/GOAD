# Sophos XGS (SFOS Home) extension

Adds a Sophos Firewall XGS / SFOS appliance to the lab at `{{ip_range}}.53`
and applies a GOAD configuration template through the **API** (with an
`Entities.xml` import as fallback).

The official ISO and the **Home license** are **not** redistributed. You
download both from Sophos.

## What you need

1. [Sophos Firewall Home](https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition) ISO
2. A Sophos ID and a **Home** license (free for home / lab use)
3. A hypervisor template / VM created from that ISO
4. Two NICs on the VM if possible: WAN (Port1) + LAN (Port2 = lab network)

Recommended VM size: 2 vCPU, 4 GB RAM, 16 GB disk.

## First boot (once per lab)

SFOS always starts with a first-boot wizard. Ansible cannot skip this.

1. Install SFOS from the ISO
2. Register / apply the **Home** license under Administration > Licensing
3. Set the `admin` password at first-boot, then pass it as `sophos_admin_password` or env `SOPHOS_ADMIN_PASSWORD`
4. Put the LAN interface on `{{ip_range}}.53/24`
5. Enable the API:
   - Administration > Settings > API
   - Enable API
   - Allow the lab subnet
6. Confirm `https://{{ip_range}}.53:4444/` opens from the control node

Then:

```
load <instance_id>
install_extension sophos_xgs
```

Pass the first-boot admin password as extra-var `sophos_admin_password`
or environment variable `SOPHOS_ADMIN_PASSWORD` (do not commit it).

## What Ansible applies

Role `sophos_xgs_config` POSTs XML to:

`https://<lan-ip>:4444/webconsole/APIController`

Payloads (in order):

| File | Purpose |
| --- | --- |
| `api/01_login_check.xml.j2` | Login + read IP hosts |
| `api/02_ip_hosts.xml.j2` | Lab network + DC/SRV/Wazuh/Kali objects |
| `api/03_local_service_acl.xml.j2` | Allow HTTPS/SSH/API from the lab |
| `api/04_firewall_rules.xml.j2` | LAN-to-LAN, LAN-to-WAN, Kali-to-Windows |
| `api/05_admin_api.xml.j2` | Keep API enabled for the lab subnet |

Fallback: `/tmp/sophos_xgs_Entities.xml` can be imported in the UI
(Backup & Firmware > Import). Schema details differ slightly by SFOS
version; use the API payloads if import rejects a node.

SDK reference: <https://github.com/sophos/sophos-firewall-sdk>

## Provider notes

### Ludus

Build a template from the ISO and name it `sophos-xgs-home-template`.

### VirtualBox / VMware

Package the installed SFOS VM as a local Vagrant box named `goad/sophos-xgs`
or set `SOPHOS_XGS_BOX`.

### Proxmox

Create a template named `SophosXGS_x64` from the ISO, then install the
extension so Terraform can clone it.

### AWS / Azure

Home license is on-prem only. See `providers/aws/README.md`.

## Default objects

- LAN IP: `.53`
- Objects prefixed `GOAD-`
- Kali `.50`, Wazuh `.51`, DCs `.10-.12`, servers `.22-.24`
