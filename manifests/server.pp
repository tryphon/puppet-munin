class munin::server ($content = ''){
  package { 'munin': }

  file { '/etc/munin/munin.conf':
    content => "includedir /etc/munin/munin-conf.d\n",
    require => Package['munin']
  }

  file { '/etc/munin/munin-conf.d/graph.conf':
    content => "graph_strategy cgi\n",
    require => Package['munin']
  }

  file { '/etc/munin/munin-conf.d/local.conf':
    content => $content,
    require => Package['munin']
  }


}
