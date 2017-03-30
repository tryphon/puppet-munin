define munin::snmp::host($plugins = []) {
  $plugin_names = join($plugins, ' ')
  exec { "munin-snmp-host-$name":
    command => "munin-snmp-host create $name $plugin_names",
    unless  => "munin-snmp-host check $name $plugin_names",
    require => [Package['munin-node'], File['/usr/local/sbin/munin-snmp-host']],
    notify => Service['munin-node']
  }
}
