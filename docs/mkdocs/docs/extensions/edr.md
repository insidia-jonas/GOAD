# Per-host EDR

The default playbook (`edr.yml`) installs security agents according to the
`edr` list on each host in `ad/<lab>/data/config.json`.

## Values

| Value | What gets installed |
| --- | --- |
| `wazuh` | Wazuh agent (needs the Wazuh manager on `.51`) |
| `sysmon` | Sysmon with the lab Wazuh config |
| `defender` | Windows Defender realtime **on** (overrides `defender_off` for that host) |
| `sophos` | Sophos Endpoint / Intercept X (**bring your own installer**) |
| `elastic` | Elastic Agent enrolled to Fleet (**bring your own Fleet URL + token**) |
| `none` | Skip agents on that host |

`wazuh` implies Sysmon as well. The default for domain hosts is
`["wazuh", "sysmon"]`. Attacker VMs default to `["none"]`.

## Example

```json
"ws01": {
  "edr": ["wazuh", "sysmon", "defender"]
},
"srv02": {
  "edr": ["none"]
},
"dc01": {
  "edr": ["sophos"]
}
```

Change the lists **before** `goad install` / provisioning. To re-apply later:

```
# from the instance console
provision -p edr.yml
```

(or re-run the `edr.yml` playbook with the same inventory).

## Sophos Endpoint (Windows)

The lab does not ship Sophos binaries. Set one of:

```yaml
sophos_endpoint_installer_url: "https://your-share/SophosSetup.exe"
# or
sophos_endpoint_installer_src: "/opt/installers/SophosSetup.exe"
```

as extra vars. Hosts with `"sophos"` in `edr` then run the installer silently.

## Elastic Defend

Requires a Fleet server (for example the `elk` extension plus Fleet):

```yaml
elastic_fleet_url: "https://192.168.56.50:8220"
elastic_enrollment_token: "...."
```

## Wazuh rules

The manager is installed on **4.14.x** and loads:

- SOCFortress [Wazuh-Rules](https://github.com/socfortress/Wazuh-Rules) (fixed so the pack actually installs)
- Custom MITRE / AD / red-team / file-server / MSSQL rules
- Optional Sigma conversion (`wazuh_install_sigma_rules`, default `true`)
