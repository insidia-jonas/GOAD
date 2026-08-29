# Red-team lab (this fork)

This GOAD fork is a full red-team range: AD + file server + SIEM + selectable
EDR + an optional perimeter firewall. This page is the configuration
reference for the extra features.

## What you get

| Area | Default | How to change |
| --- | --- | --- |
| Windows Eval 1-hour shutdown | **Off** (WLMS disabled on every Windows VM) | Role `settings/disable_eval_shutdown` in `build.yml` |
| File server | **oldtown / srv04** — department shares + dummy files | `ad/GOAD/data/inventory` `[file_server]` |
| SQL creds on shares | Planted at provision time from `config.json` | Role `vulns/fileserver` |
| Sample MSSQL DBs | Kingdoms / NightWatch / FreeCities / Citadel | Role `mssql_labdata` |
| SIEM | Wazuh **4.14.x** on `.51` (SOCFortress + Sigma + custom rules) | Host `edr` list; see [wazuh](../extensions/wazuh.md) |
| Per-host EDR | `["wazuh", "sysmon"]` on domain hosts | `ad/GOAD/data/config.json` → `hosts.<name>.edr` |
| Perimeter | **Debian router** on `.53` | Enable `sophos_xgs` to replace it |
| Elastic Defend | Off (needs `elastic_edr` + `"elastic"` in `edr`) | [elastic_edr](../extensions/elastic_edr.md) |
| Bitdefender | Off (needs GravityZone trial package id) | [edr](../extensions/edr.md) |
| Sophos Endpoint | Off (BYO installer) | `sophos_endpoint_installer_url` / `_src` |
| Sophos XGS | Off (BYO ISO + Home license) | `install_extension sophos_xgs` |

Attacker VMs (kali / commando) default to `"edr": ["none"]`.

## Lab install

```
./goad.sh -p <provider>
set_lab GOAD
# optional, before create:
set_extensions sophos_xgs elastic_edr
install
```

Or after a running instance:

```
load <instance_id>
install_extension sophos_xgs
install_extension elastic_edr
provision -p edr.yml
```

`edr.yml` is in the default playbook list. Enabled `*_inventory` files are
loaded automatically so Fleet / Sophos hosts are visible.

## Per-host EDR (`config.json`)

Edit **before** `goad install` (or re-run `provision -p edr.yml`):

```json
"dc01": { "edr": ["wazuh", "sysmon"] },
"dc02": { "edr": ["elastic"] },
"dc03": { "edr": ["bitdefender"] },
"ws01": { "edr": ["wazuh", "sysmon", "defender"] },
"srv02": { "edr": ["none"] }
```

| Value | Installs | Extra config |
| --- | --- | --- |
| `wazuh` | Wazuh agent (implies Sysmon) | Manager on `.51` |
| `sysmon` | Sysmon only | — |
| `defender` | Windows Defender realtime **on** | Overrides `[defender_off]` |
| `sophos` | Sophos Endpoint | `sophos_endpoint_installer_url` or `_src` |
| `elastic` | Elastic Agent + Defend | `elastic_edr` **or** `elastic_fleet_url` + `elastic_enrollment_token` |
| `bitdefender` | BEST / GravityZone | `bitdefender_gz_package_id` or `BITDEFENDER_GZ_PACKAGE_ID` |
| `none` | Skip | — |

Full notes: [edr](../extensions/edr.md).

## Perimeter: Debian router vs Sophos XGS

Both use LAN **`{{ip_range}}.53`**. They never run at the same time when
`replace_debian_router` is true (the default).

```
                    ┌─────────────────┐
   Internet / WAN ──┤ Debian router   │── Lab LAN .10–.52
                    │ (default) .53   │
                    └─────────────────┘

   set_extensions sophos_xgs  /  install_extension sophos_xgs

                    ┌─────────────────┐
   Internet / WAN ──┤ Sophos XGS      │── Lab LAN .10–.52
                    │ (replaces .53)  │
                    └─────────────────┘
```

### Debian router (default)

- VM name: `router` / `{{lab_name}}-ROUTER`
- Box: Debian 12 (`bento/debian-12` or Ludus `debian-12-x64-server-template`)
- Ansible group: `lab_router`
- Playbook: `router.yml` (ip_forward + NAT masquerade)
- SSH (Ludus): `debian` / `debian` · (Vagrant): `vagrant`

The hypervisor (`.1`) remains the usual default gateway for Ludus/Vagrant
NAT. Point `route_gateway` at `.53` and set `add_route=yes` in inventory
if you want lab egress through the perimeter.

### Sophos XGS (optional extension)

Configurable in `extensions/sophos_xgs/data/config.json`:

| Key | Default | Meaning |
| --- | --- | --- |
| `lab_extension.replace_debian_router` | `true` | Omit the Debian router VM when this extension is enabled |
| `hosts.sophos_xgs.lan_last_octet` | `53` | LAN address (must stay `.53` if it replaces the router) |
| `hosts.sophos_xgs.iso_path` | `""` | Local path to your SFOS ISO (not redistributed) |
| `hosts.sophos_xgs.license_path` | `""` | Local path to the Home license file (apply in the UI) |
| `hosts.sophos_xgs.local_admin_password` | `""` | Leave empty; pass at runtime |

Runtime / extra-vars:

| Variable | Env | Purpose |
| --- | --- | --- |
| `sophos_admin_password` | `SOPHOS_ADMIN_PASSWORD` | Admin password from first-boot |
| `sophos_iso_path` | `SOPHOS_XGS_ISO` | Remember where the ISO lives |
| `sophos_license_path` | `SOPHOS_XGS_LICENSE` | Remember where the license file lives |

ISO + license file alone do **not** skip first-boot. You still:

1. Build a hypervisor template from the ISO (Ludus `sophos-xgs-home-template`, Vagrant box `goad/sophos-xgs`, Proxmox `SophosXGS_x64`)
2. Finish the SFOS wizard, apply the Home license, set admin, LAN `.53`, enable API `:4444`
3. `install_extension sophos_xgs`

Ansible then pushes lab objects and firewall rules. If the instance already
had a Debian router, destroy that VM after the extension rewrites the
provider files (`update_instance_files` / `install_extension`).

Home license is on-prem only (no AWS/Azure).

## Elastic (30-day trial)

```
install_extension elastic_edr
```

- VM `.54`, 8 GB RAM
- Trial: `POST /_license/start_trial` on the VM (no key in git)
- Kibana `http://{{ip_range}}.54:5601` — password only in `/opt/elastic/credentials.env`
- Then `"edr": ["elastic"]` and `provision -p edr.yml`

## Bitdefender (GravityZone trial)

```yaml
bitdefender_gz_package_id: "<id from setupdownloader_[ID].exe>"
```

or `BITDEFENDER_GZ_PACKAGE_ID`. No binaries in the repo.

## Wazuh

Manager `.51`, agents follow the `edr` list. Rules: SOCFortress (fixed
install), Sigma (default on), custom AD / red-team / file-server / MSSQL.

## File server + SQL

- **oldtown (srv04)**: Finance, HR, Legal, IT, SQL, Public, Archives
- Plaintext SQL connection strings planted from `config.json` (not hardcoded in roles)
- srv02 also has smaller `sql` / `it` shares
- Sample databases via `mssql_labdata`

## Re-apply after config changes

```
provision -p router.yml
provision -p edr.yml
provision_extension sophos_xgs
provision_extension elastic_edr
```
