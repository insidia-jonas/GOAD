# Clone a Proxmox template you created from the official SFOS Home ISO.
# Template name: SophosXGS_x64
"sophos_xgs" = {
  name    = "sophos_xgs"
  desc    = "Sophos XGS Home (SFOS) - {{ip_range}}.53"
  cores   = 2
  memory  = 4096
  clone   = "SophosXGS_x64"
  dns     = "{{ip_range}}.1"
  ip      = "{{ip_range}}.53/24"
  gateway = "{{ip_range}}.1"
}
