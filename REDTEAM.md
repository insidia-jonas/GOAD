# Red-team lab — features and configuration

Operator handbook for this GOAD fork. The MkDocs copy lives at
`docs/mkdocs/docs/labs/redteam.md`.

## Features

| Feature | Default | Config |
| --- | --- | --- |
| Eval 1h shutdown (WLMS) | Disabled on all Windows VMs | `settings/disable_eval_shutdown` |
| File server | oldtown / srv04 | `[file_server]` in inventory |
| SQL creds on shares | From `ad/GOAD/data/config.json` at provision time | `vulns/fileserver` |
| Wazuh SIEM | 4.14.x on `.51` | Host `edr` includes `wazuh` |
| Per-host EDR | `["wazuh","sysmon"]` | `hosts.<name>.edr` in `config.json` |
| Debian router | **On** `.53` | Playbook `router.yml` |
| Sophos XGS | Off | `set_extensions sophos_xgs` — **replaces** the Debian router |
| Elastic Defend | Off | `install_extension elastic_edr` + `"elastic"` in `edr` |
| Bitdefender | Off | `bitdefender_gz_package_id` / `BITDEFENDER_GZ_PACKAGE_ID` |
| Sophos Endpoint | Off | `sophos_endpoint_installer_url` or `_src` |

## EDR values

`wazuh` · `sysmon` · `defender` · `sophos` · `elastic` · `bitdefender` · `none`

```json
"dc01": { "edr": ["elastic"] },
"dc02": { "edr": ["bitdefender"] }
```

Re-apply: `provision -p edr.yml`

## Perimeter

Debian router and Sophos share LAN `.53`. Enabling `sophos_xgs` sets
`replace_debian_router: true` (see `extensions/sophos_xgs/data/config.json`)
and **does not create** the Debian VM.

```
set_extensions sophos_xgs
install
```

or `install_extension sophos_xgs` on an existing instance, then destroy the
old `router` VM.

ISO + license file are BYO. First-boot (wizard, license UI, API, LAN IP) is
still manual. Then Ansible applies objects/rules.
Admin password: `sophos_admin_password` / `SOPHOS_ADMIN_PASSWORD`.

## Extra-vars / environment

| Item | Extra-var | Environment |
| --- | --- | --- |
| Sophos XGS admin | `sophos_admin_password` | `SOPHOS_ADMIN_PASSWORD` |
| Sophos ISO path (note only) | `sophos_iso_path` | `SOPHOS_XGS_ISO` |
| Sophos license path (note only) | `sophos_license_path` | `SOPHOS_XGS_LICENSE` |
| Sophos Endpoint installer | `sophos_endpoint_installer_url` | — |
| Elastic Fleet (external) | `elastic_fleet_url`, `elastic_enrollment_token` | — |
| Bitdefender package | `bitdefender_gz_package_id` | `BITDEFENDER_GZ_PACKAGE_ID` |

## Playbooks

- `router.yml` — Debian perimeter (skipped if the group is empty)
- `edr.yml` — Wazuh + Defender + Sophos Endpoint + Bitdefender + Elastic
- `elastic.yml` — Elastic Security stack (needs `elastic_server`)
