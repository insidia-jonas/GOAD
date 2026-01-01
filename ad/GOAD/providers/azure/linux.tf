# "lx01" = {
#   name               = "lx01"
#   linux_sku          = "22_04-lts-gen2"
#   linux_version      = "latest"
#   private_ip_address = "{{ip_range}}.40"
#   password           = "suppaP@ssw0rd$"
#   size               = "Standard_B2s"
# }
"wazuh" = {
  name               = "wazuh"
  linux_sku          = "22_04-lts-gen2"
  linux_version      = "latest"
  private_ip_address = "{{ip_range}}.51"
  password           = "W@zuhS3rv3r!"
  size               = "Standard_D4s_v3"
}