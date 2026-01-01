"commando" = {
  name               = "COMMANDO"
  desc               = "COMMANDO - Windows Attack Machine - {{ip_range}}.51"
  cores              = 2
  memory             = 8192
  clone              = "CommandoVM_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.51/24"
  gateway            = "{{ip_range}}.1"
}
