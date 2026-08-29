# WAZUH extension

- Extension Name: wazuh
- Description: Add Wazuh 4.14.x SIEM/EDR plus SOCFortress, Sigma and GOAD custom rules. Agents follow each host `edr` list in config.json.
- Machine name : {{lab_name}}-WAZUH
- Compatible with labs : *

## prerequisites

On ludus prepare template :
```
ludus templates add -d ubuntu-22.04-x64-server
ludus templates build
```

## Install
```
instance_id> install_extension wazuh
```


## credits
- https://github.com/aleemladha (https://github.com/Orange-Cyberdefense/GOAD/pull/215)