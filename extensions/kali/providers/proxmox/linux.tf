"kali" = {
  name               = "KALI"
  desc               = "KALI - Kali Linux Attack Machine - {{ip_range}}.50"
  cores              = 2
  memory             = 4096
  clone              = "Kali_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.50/24"
  gateway            = "{{ip_range}}.1"
}
