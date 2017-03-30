class munin::anode::default_plugins {

  # some default plugins
  munin::plugin { [ cpu, df, iostat, load, memory, netstat, swap ]: }
  munin::plugin { if_eth0: script => if_, require => Package[ethtool] }

  package { ethtool: }

  # remove some debian default plugin
  munin::plugin {
    [ open_inodes, open_files, irqstats, interrupts, entropy, df_inode, if_err_eth0, if_err_eth1, vmstat, forks ]:
    ensure => absent
  }

  # disable the (verbose) cron for /etc/munin/plugins/apt_all
  exec { "sed -i '/apt_all/ s/^\\(.*\\)$/# \\1/' /etc/cron.d/munin-node":
    unless => "/bin/grep -q '#.*apt_all' /etc/cron.d/munin-node",
    require => Package['munin-node']
  }

}
