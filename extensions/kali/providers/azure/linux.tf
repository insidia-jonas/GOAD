"kali" = {
  name               = "kali"
  publisher          = "kali-linux"
  offer              = "kali"
  linux_sku          = "kali-2024-1"
  linux_version      = "latest"
  private_ip_address = "{{ip_range}}.50"
  password           = "kali"
  size               = "Standard_B2s"  # 2cpu/4G
}
