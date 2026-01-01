"commando" = {
  name               = "commando"
  domain             = ""
  windows_sku        = "Windows_Server-2022-English-Full-Base"
  ami                = "ami-0d2c2e5e5e5e5e5e5"
  instance_type      = "t2.large"
  private_ip_address = "{{ip_range}}.51"
  password           = "CommandoVM!"
}
