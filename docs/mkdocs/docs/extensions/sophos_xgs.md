# sophos_xgs

- Extension name : `sophos_xgs`
- Description : Sophos Firewall XGS (SFOS) with a GOAD API / `Entities.xml` configuration template
- Compatibility : GOAD, GOAD-Light, NHA, SCCM
- Providers : ludus / virtualbox / vmware / proxmox (Home license is on-prem only)
- Machine : `sophos_xgs` (`ip_range.53`)

!!! warning "Bring your own ISO and Home license"
    This repository does **not** ship the SFOS ISO or a license key.
    Register for [Sophos Firewall Home](https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition),
    download the ISO, and apply the Home license during first boot.

## Size

- 2 vCPU / 4 GB RAM / 16 GB disk
- Two NICs recommended: WAN (Port1) + LAN (Port2 = lab `.53`)

## First boot

Ansible talks to the HTTPS API on port `4444`. That only works after you:

1. Install SFOS from the official ISO
2. Apply the **Home** license (Administration > Licensing)
3. Set the `admin` password during first-boot, then pass it as `sophos_admin_password` or `SOPHOS_ADMIN_PASSWORD`
4. Address the LAN interface as `{{ip_range}}.53/24`
5. Enable API access from the lab subnet

Then:

```
load <instance_id>
install_extension sophos_xgs
```

## Configuration applied

The `sophos_xgs_config` role POSTs XML to
`https://<lan-ip>:4444/webconsole/APIController`:

- IP hosts for the lab network, DCs, servers, Wazuh, Kali
- Local service ACL so the lab can reach HTTPS / API / SSH
- Firewall rules: LAN-to-LAN, LAN-to-WAN, Kali-to-Windows
- API left enabled for the lab subnet

If an SFOS version rejects an API object, import the generated
`/tmp/sophos_xgs_Entities.xml` from **Backup & Firmware > Import**, or
create the same objects in the UI. Templates live under
`extensions/sophos_xgs/ansible/roles/sophos_xgs_config/templates/`.

Override the admin password with `sophos_admin_password` or
`extensions/sophos_xgs/data/config.json` → `local_admin_password`.

## Provider templates

| Provider | You prepare |
| --- | --- |
| Ludus | template `sophos-xgs-home-template` from the ISO |
| VirtualBox / VMware | local Vagrant box `goad/sophos-xgs` (or `SOPHOS_XGS_BOX`) |
| Proxmox | clone template `SophosXGS_x64` |
| AWS / Azure | not supported with a Home license |

Full notes: `extensions/sophos_xgs/README.md`.
