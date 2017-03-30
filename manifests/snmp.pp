class munin::snmp {
  file { '/usr/local/sbin/munin-snmp-host':
    source => "puppet:///modules/munin/munin-snmp-host.rb",
    mode   => '0755'
  }

  # sudo /usr/sbin/munin-node-configure --snmp=HOST | grep "yes" | awk '{ print $1 }' | sed 's/snmp__//'
}
