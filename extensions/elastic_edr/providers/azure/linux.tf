"elastic" = {
  name               = "elastic"
  linux_sku          = "22_04-lts-gen2"
  linux_version      = "latest"
  private_ip_address = "{{ip_range}}.54"
  password           = "{{ lab_name }}-elastic"
  size               = "Standard_B2ms"  # 2cpu/8G
}
