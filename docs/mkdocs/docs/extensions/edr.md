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
| `elastic` | Elastic Agent + Elastic Defend (lab Fleet trial **or** your Fleet URL/token) |
| `bitdefender` | Bitdefender Endpoint Security Tools / GravityZone (**trial package id**) |
| `none` | Skip agents on that host |

`wazuh` implies Sysmon as well. The default for domain hosts is
`["wazuh", "sysmon"]`. Attacker VMs default to `["none"]`.

Do **not** set `elastic` or `bitdefender` as the default for every host —
those options need extra lab pieces (the `elastic_edr` VM, or a GravityZone
package).

## Example

```json
"ws01": {
  "edr": ["wazuh", "sysmon", "defender"]
},
"srv02": {
  "edr": ["none"]
},
"dc01": {
  "edr": ["elastic"]
},
"dc02": {
  "edr": ["bitdefender"]
},
"dc03": {
  "edr": ["sophos"]
}
```

Change the lists **before** `goad install` / provisioning. To re-apply later:

```
# from the instance console
provision -p edr.yml
```

(or re-run the `edr.yml` playbook with the same inventory). Enabled extension
inventories (for example `elastic_edr`) are included automatically.

## Sophos Endpoint (Windows)

The lab does not ship Sophos binaries. Set one of:

```yaml
sophos_endpoint_installer_url: "https://your-share/SophosSetup.exe"
# or
sophos_endpoint_installer_src: "/opt/installers/SophosSetup.exe"
```

as extra vars. Hosts with `"sophos"` in `edr` then run the installer silently.

## Elastic Defend (test / trial license)

Two ways:

### A. Lab VM (`elastic_edr` extension) — recommended

`install_extension elastic_edr` brings up Elasticsearch + Kibana + Fleet on
`.54` and starts Elastic's **30-day self-managed trial**
(`POST /_license/start_trial`). No license file is committed.

Then set `"elastic"` on the hosts you want and re-run `edr.yml` or
`provision_extension elastic_edr`.

Kibana: `http://{{ip_range}}.54:5601` (password only on the VM,
`/opt/elastic/credentials.env`).

Details: [elastic_edr](elastic_edr.md).

### B. External Fleet (Elastic Cloud trial or your own)

```yaml
elastic_fleet_url: "https://your-fleet.example:8220"
elastic_enrollment_token: "...."
```

## Bitdefender (GravityZone trial)

The lab does not ship Bitdefender binaries or a license. Create a
[GravityZone trial](https://www.bitdefender.com/business/free-trials.html),
build an installation package, then either:

**Package id** (from `setupdownloader_[PACKAGEID].exe` — the base64 string
inside the filename):

```yaml
bitdefender_gz_package_id: "aHR0cHM6Ly9..."
# or environment variable BITDEFENDER_GZ_PACKAGE_ID
```

Ansible downloads Bitdefender's public MSI wrapper
(`BEST_downloaderWrapper.msi`) and runs:

`msiexec /qn GZ_PACKAGE_ID=... REBOOT_IF_NEEDED=0`

**Or** a downloaded EXE:

```yaml
bitdefender_installer_url: "https://your-share/setupdownloader_XXXX.exe"
# or
bitdefender_installer_src: "/opt/installers/setupdownloader.exe"
```

Silent flags default to `/bdparams /silent`.

## Wazuh rules

The manager is installed on **4.14.x** and loads:

- SOCFortress [Wazuh-Rules](https://github.com/socfortress/Wazuh-Rules) (fixed so the pack actually installs)
- Custom MITRE / AD / red-team / file-server / MSSQL rules
- Optional Sigma conversion (`wazuh_install_sigma_rules`, default `true`)
