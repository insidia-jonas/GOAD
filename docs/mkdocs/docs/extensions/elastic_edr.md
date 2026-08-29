# elastic_edr

- Extension name : `elastic_edr`
- Description : Self-managed Elastic Security **8.x** with a **30-day trial**, Fleet and Elastic Defend
- Compatibility : `*`
- Providers : virtualbox / vmware / aws / azure / proxmox / ludus
- Machine : `elastic` (`ip_range.54`, 8 GB RAM)
- Agent selection : per host via `config.json` `edr` → `elastic` (see [edr](edr.md))

!!! warning "impacts"
    Adds a heavy Linux VM. Do not confuse with the older `elk` extension on `.50`
    (Winlogbeat only, no Fleet / no Elastic Defend).

## Trial

Provisioning starts Elastic's self-managed trial on the VM:

`POST /_license/start_trial?acknowledge=true`

No license key is stored in the repository. Elastic Defend needs that trial
(or a Platinum / Enterprise / Elastic Cloud subscription).

## Prerequisites

```
ludus templates add -d ubuntu-22.04-x64-server
ludus templates build
```

A lab instance must already exist. On AWS / Azure the Linux admin password
is `<lab_name>-elastic` (templated, not stored as a literal in git).

## Installation

```
load <instance_id>
install_extension elastic_edr
```

Put `"elastic"` in the host `edr` list **before** provisioning agents:

```json
"dc01": {
  "edr": ["elastic", "sysmon"]
}
```

Then `provision_extension elastic_edr` or `provision -p edr.yml`.

## UI

- Kibana: `http://{{ip_range}}.54:5601`
- Built-in user: `elastic`
- Password file on the VM only: `/opt/elastic/credentials.env`

## External Fleet

If you already have an Elastic Cloud trial or another Fleet server, skip this
extension and set extra-vars (see [edr](edr.md)).
