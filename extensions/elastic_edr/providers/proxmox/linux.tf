"elastic" = {
  name               = "ELASTIC"
  desc               = "ELASTIC - Elastic Security 8.x trial - {{ip_range}}.54"
  cores              = 4
  memory             = 8192
  clone              = "Ubuntu2204_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.54/24"
  gateway            = "{{ip_range}}.1"
}
