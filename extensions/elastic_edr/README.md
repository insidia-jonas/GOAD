# Elastic Security EDR extension

- Extension name: `elastic_edr`
- Description: Self-managed **Elastic Security 8.x** with Fleet and **Elastic Defend**
- Machine: `{{lab_name}}-ELASTIC` at `{{ip_range}}.54`
- Compatible with labs: `*`
- RAM: **8 GB** (Elasticsearch + Kibana + Fleet Server)

This is **not** the old `elk` extension (Elasticsearch 7 + Winlogbeat on `.50`).
Use `elastic_edr` when you want Elastic as an **EDR** option.

## Trial license (no key in git)

On first provision the role calls:

`POST /_license/start_trial?acknowledge=true`

That starts Elastic's **30-day self-managed trial** on the VM (Platinum-class
features, including Elastic Defend). No license file is committed or
redistributed.

- One trial per major version per cluster
- After 30 days Defend / Fleet features degrade; start a new lab or request an
  extension from Elastic
- Alternative: an **Elastic Cloud** trial — skip this VM and pass
  `elastic_fleet_url` + `elastic_enrollment_token` as extra-vars

## Prerequisites

```
ludus templates add -d ubuntu-22.04-x64-server
ludus templates build
```

The VM needs outbound HTTPS to `artifacts.elastic.co`.

On AWS / Azure the Linux admin password is rendered as `<lab_name>-elastic`
(no password is stored as a literal in git).

## Install

1. Set `"edr": ["elastic"]` (optionally with `sysmon`) on the hosts you want
   in `ad/<lab>/data/config.json`
2. From the instance console:

```
load <instance_id>
install_extension elastic_edr
```

Or later:

```
provision_extension elastic_edr
provision -p edr.yml
```

## After install

- Kibana: `http://{{ip_range}}.54:5601`
- User: `elastic`
- Password: **only** on the VM in `/opt/elastic/credentials.env` (never logged)
- Fleet: `https://{{ip_range}}.54:8220`
- Default Windows policy: **GOAD Windows EDR** with Elastic Defend preset
  `EDRComplete` (override with `elastic_defend_preset`, e.g. `DataCollection`
  if you want telemetry without blocking)

Windows agents enroll with `--insecure` because Fleet uses a lab self-signed
certificate.

## Uninstall

Not implemented. Destroy the VM / disable the extension.
