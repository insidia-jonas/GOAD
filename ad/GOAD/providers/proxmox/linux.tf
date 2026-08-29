{% if not replace_debian_router|default(false) %}
"router" = {
  name               = "ROUTER"
  desc               = "Debian lab router / perimeter - {{ip_range}}.53"
  cores              = 1
  memory             = 1024
  clone              = "Debian12_x64"
  dns                = "{{ip_range}}.1"
  ip                 = "{{ip_range}}.53/24"
  gateway            = "{{ip_range}}.1"
}
{% endif %}
