# sophos_xgs

- Extension name : `sophos_xgs`
- Description : Configurable Sophos Firewall XGS (SFOS Home). **Replaces the Debian lab router** on `.53`.
- Compatibility : GOAD, GOAD-Light, NHA, SCCM
- Providers : ludus / virtualbox / vmware / proxmox (Home license is on-prem only)
- Machine : `sophos_xgs` (`ip_range.53`) — same IP as the Debian router it replaces

!!! warning "Bring your own ISO and Home license"
    This repository does **not** ship the SFOS ISO or a license key.
    Register for [Sophos Firewall Home](https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition),
    download the ISO, and apply the Home license during first boot.
    Putting the ISO and license file on disk does **not** skip first-boot.

!!! info "Replaces the Debian router"
    GOAD’s default perimeter is a small Debian VM on `.53` (`lab_router`).
    Enabling this extension sets `replace_debian_router: true` and **omits**
    that VM from Vagrant / Ludus / Terraform. Sophos becomes `[perimeter]`.

## Configuration

`extensions/sophos_xgs/data/config.json`:

```json
{
  "lab_extension": {
    "replace_debian_router": true,
    "hosts": {
      "sophos_xgs": {
        "lan_last_octet": 53,
        "iso_path": "",
        "license_path": "",
        "local_admin_password": ""
      }
    }
  }
}
```

| Setting | Default | Notes |
| --- | --- | --- |
| `replace_debian_router` | `true` | Keep `true` so Sophos owns `.53` |
| `iso_path` / env `SOPHOS_XGS_ISO` | empty | Your local ISO path (template build) |
| `license_path` / env `SOPHOS_XGS_LICENSE` | empty | License file — apply in the UI |
| `sophos_admin_password` / `SOPHOS_ADMIN_PASSWORD` | empty | Required for the API playbook |

Enable **before** `create` so the Debian router is never built:

```
set_extensions sophos_xgs
install
```

On an existing lab:

```
install_extension sophos_xgs
```

Then destroy the leftover Debian `router` VM if it is still running.

## Size

- 2 vCPU / 4 GB RAM / 16 GB disk
- Two NICs recommended: WAN (Port1) + LAN (Port2 = lab `.53`)

## First boot (still manual)

Ansible talks to the HTTPS API on port `4444` only after you:

1. Build a template from the official ISO
2. Apply the **Home** license (Administration > Licensing)
3. Set the `admin` password, then pass `sophos_admin_password` / `SOPHOS_ADMIN_PASSWORD`
4. Address the LAN interface as `{{ip_range}}.53/24`
5. Enable API access from the lab subnet

```
load <instance_id>
install_extension sophos_xgs
```

## Configuration applied

The `sophos_xgs_config` role POSTs XML to
`https://<lan-ip>:4444/webconsole/APIController`:

- IP hosts for the lab network, DCs, servers, Wazuh, Kali, Elastic
- Local service ACL so the lab can reach HTTPS / API / SSH
- Firewall rules: LAN-to-LAN, LAN-to-WAN, Kali-to-Windows
- API left enabled for the lab subnet

If an SFOS version rejects an API object, import `/tmp/sophos_xgs_Entities.xml`
from **Backup & Firmware > Import**.

## Provider templates

| Provider | You prepare |
| --- | --- |
| Ludus | template `sophos-xgs-home-template` from the ISO |
| VirtualBox / VMware | local Vagrant box `goad/sophos-xgs` (or `SOPHOS_XGS_BOX`) |
| Proxmox | clone template `SophosXGS_x64` |
| AWS / Azure | not supported with a Home license |

See also the [red-team lab](../labs/redteam.md) handbook.
