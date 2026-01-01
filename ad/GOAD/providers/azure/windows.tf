# Standard_B2s : 2 CPU / 4GB
# Standard_B2ms : 2CPU / 8GB
# Standard_B4ms : 4 cpu / 16 GB
"dc01" = {
  name               = "dc01"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2025-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.10"
  password           = "8dCT-DJjgScp"
  size               = "Standard_B2s"
}
"dc02" = {
  name               = "dc02"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2025-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.11"
  password           = "NgtI75cKV+Pu"
  size               = "Standard_B2s"
}
"dc03" = {
  name               = "dc03"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2022-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.12"
  password           = "Ufe-bVXSx9rk"
  size               = "Standard_B2s"
}
"srv02" = {
  name               = "srv02"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2025-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.22"
  password           = "NgtI75cKV+Pu"
  size               = "Standard_B2s"
}
"srv03" = {
  name               = "srv03"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2022-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.23"
  password           = "978i2pF43UJ-"
  size               = "Standard_B2s"
}
# Windows Server 2008 R2 - Legacy server
"srv04" = {
  name               = "srv04"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2008-R2-SP1"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.24"
  password           = "L3g4cyS3rv3r!"
  size               = "Standard_B2s"
}
# Windows 10 workstation
"ws02" = {
  name               = "ws02"
  publisher          = "MicrosoftWindowsDesktop"
  offer              = "Windows-10"
  windows_sku        = "win10-22h2-pro"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.32"
  password           = "W0rkst4t10n!"
  size               = "Standard_B2s"
}
