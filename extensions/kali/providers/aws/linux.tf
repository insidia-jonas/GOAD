"kali" = {
  name               = "kali"
  linux_sku          = "kali-linux"
  linux_version      = "latest"
  ami                = "ami-0c7217cdde317cfec"
  private_ip_address = "{{ip_range}}.50"
  password           = "kali"
  size               = "t2.medium"  # 2cpu/4G
}
