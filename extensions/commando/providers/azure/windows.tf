"commando" = {
  name               = "commando"
  publisher          = "MicrosoftWindowsDesktop"
  offer              = "Windows-11"
  windows_sku        = "win11-22h2-pro"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.51"
  password           = "CommandoVM!"
  size               = "Standard_B2ms"  # 2cpu/8G
}
