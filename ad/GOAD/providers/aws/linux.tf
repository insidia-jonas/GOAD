# "lx01" = {
#   name               = "lx01"
#   linux_sku          = "22_04-lts-gen2"
#   linux_version      = "latest"
#   ami                = "ami-00c71bd4d220aa22a"
#   private_ip_address = "{{ip_range}}.40"
#   password           = "suppaP@ssw0rd$"
#   size               = "t2.medium"
# }
"wazuh" = {
  name               = "wazuh"
  linux_sku          = "22_04-lts-gen2"
  linux_version      = "latest"
  ami                = "ami-00c71bd4d220aa22a"
  private_ip_address = "{{ip_range}}.51"
  password           = "W@zuhS3rv3r!"
  size               = "t2.xlarge"
}