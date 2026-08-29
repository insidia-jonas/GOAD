# Sophos XGS (SFOS Home) extension

Configurable perimeter firewall. When this extension is **enabled**, it
**replaces the Debian lab router** on `{{ip_range}}.53`.

The official ISO and the **Home license** are **not** redistributed.

## Configuration

`data/config.json`:

| Key | Default | Meaning |
| --- | --- | --- |
| `lab_extension.replace_debian_router` | `true` | Drop the Debian `router` VM from provider files |
| `hosts.sophos_xgs.lan_last_octet` | `53` | LAN IP (keep `.53` to replace the router) |
| `hosts.sophos_xgs.iso_path` | `""` | Your SFOS ISO (or env `SOPHOS_XGS_ISO`) |
| `hosts.sophos_xgs.license_path` | `""` | Home license file (or env `SOPHOS_XGS_LICENSE`) |
| `hosts.sophos_xgs.local_admin_password` | `""` | Do not commit; use `SOPHOS_ADMIN_PASSWORD` |

```
set_extensions sophos_xgs    # before create — no Debian router is built
install

# or on an existing instance
install_extension sophos_xgs
# then destroy the leftover Debian router VM
```

ISO + license on disk do **not** automate first-boot (SFOS wizard, license
UI, API enable, LAN `.53`). After that, Ansible applies objects and rules.

## What you need

1. [Sophos Firewall Home](https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition) ISO
2. A Sophos ID and a **Home** license
3. A hypervisor template / VM created from that ISO
4. Two NICs if possible: WAN (Port1) + LAN (Port2 = lab network `.53`)

Recommended VM size: 2 vCPU, 4 GB RAM, 16 GB disk.

## First boot (once per lab)

1. Install SFOS from the ISO
2. Register / apply the **Home** license under Administration > Licensing
3. Set the `admin` password, then pass `sophos_admin_password` or `SOPHOS_ADMIN_PASSWORD`
4. Put the LAN interface on `{{ip_range}}.53/24`
5. Enable the API and allow the lab subnet
6. Confirm `https://{{ip_range}}.53:4444/` opens from the control node

```
load <instance_id>
install_extension sophos_xgs
```

## What Ansible applies

Role `sophos_xgs_config` POSTs XML to
`https://<lan-ip>:4444/webconsole/APIController`:

| File | Purpose |
| --- | --- |
| `api/01_login_check.xml.j2` | Login + read IP hosts |
| `api/02_ip_hosts.xml.j2` | Lab network + DC/SRV/Wazuh/Kali/Elastic |
| `api/03_local_service_acl.xml.j2` | Allow HTTPS/SSH/API from the lab |
| `api/04_firewall_rules.xml.j2` | LAN-to-LAN, LAN-to-WAN, Kali-to-Windows |
| `api/05_admin_api.xml.j2` | Keep API enabled for the lab subnet |

Fallback: `/tmp/sophos_xgs_Entities.xml` (Backup & Firmware > Import).

## Provider notes

### Ludus

Template name: `sophos-xgs-home-template`.

### VirtualBox / VMware

Local box `goad/sophos-xgs` or `SOPHOS_XGS_BOX`.

### Proxmox

Template `SophosXGS_x64`.

### AWS / Azure

Home license is on-prem only.

## Default objects

- LAN IP: `.53` (same slot as the Debian router)
- Objects prefixed `GOAD-`
- Kali `.50`, Wazuh `.51`, Elastic `.54`, DCs `.10-.12`, servers `.22-.24`
