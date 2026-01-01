"dc01" = {
  name               = "DC01"
  desc               = "DC01 - windows server 2025 - {{ip_range}}.10"
  cores              = 2
  memory             = 3096
  clone              = "WinServer2025_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.10/24"
  gateway            = "{{ip_range}}.1"
}
"dc02" = {
  name               = "DC02"
  desc               = "DC02 - windows server 2025 - {{ip_range}}.11"
  cores              = 2
  memory             = 3096
  clone              = "WinServer2025_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.11/24"
  gateway            = "{{ip_range}}.1"
}
"dc03" = {
  name               = "DC03"
  desc               = "DC03 - windows server 2022 - {{ip_range}}.12"
  cores              = 2
  memory             = 3096
  clone              = "WinServer2022_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.12/24"
  gateway            = "{{ip_range}}.1"
}
"srv02" = {
  name               = "SRV02"
  desc               = "SRV02 - windows server 2025 - {{ip_range}}.22"
  cores              = 2
  memory             = 6240
  clone              = "WinServer2025_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.22/24"
  gateway            = "{{ip_range}}.1"
}
"srv03" = {
  name               = "SRV03"
  desc               = "SRV03 - windows server 2022 - {{ip_range}}.23"
  cores              = 2
  memory             = 5120
  clone              = "WinServer2022_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.23/24"
  gateway            = "{{ip_range}}.1"
}
"srv04" = {
  name               = "SRV04"
  desc               = "SRV04 - windows server 2008 R2 - {{ip_range}}.24"
  cores              = 2
  memory             = 2048
  clone              = "WinServer2008R2_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.24/24"
  gateway            = "{{ip_range}}.1"
}
"ws02" = {
  name               = "WS02"
  desc               = "WS02 - windows 10 - {{ip_range}}.32"
  cores              = 2
  memory             = 4096
  clone              = "Windows10_22h2_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.32/24"
  gateway            = "{{ip_range}}.1"
}