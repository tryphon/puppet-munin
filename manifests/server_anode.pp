define munin::server_anode($ip_address = $name, $load_warning = 0.4, $load_critical = 0.7, $cpu_system_warning = 40, $cpu_system_critical = 80, $cpu_user_warning = 40, $cpu_user_critical = 80, $cpu_iowait_warning = 60, $cpu_iowait_critical = 80, $mem_app_warning = 0.7, $mem_app_critical = 0.95, $extra_limits = []) {
  file { "/etc/munin/munin-conf.d/node-${name}.conf":
    content => template('munin/node.conf'),
    require => Package['munin']
  }
}
