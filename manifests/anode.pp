class munin::anode {

  package { 'munin-node': ensure => latest }

  service { 'munin-node':
    ensure    => running,
    subscribe => [Package[munin-node], File['/etc/munin/munin-node.conf']]
  }
  file { '/etc/munin/munin-node.conf':
    require => Package[munin-node]
  }

  # Directory to store local plugins
  file { ['/usr/local/share/munin', '/usr/local/share/munin/plugins']:
    ensure => directory
  }


  include munin::anode::tiger
}
