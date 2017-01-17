class munin {

  class server {
    package { 'munin': }

    file { '/etc/munin/munin.conf':
      content => "includedir /etc/munin/munin-conf.d\n"
    }

    file { '/etc/munin/munin-conf.d/graph.conf':
      content => "graph_strategy cgi\n",
      require => Package['munin']
    }

    file { '/etc/munin/munin-conf.d/local.conf':
      source => 'puppet:///files/munin/munin.conf',
      require => Package['munin']
    }

    backup::model { 'munin': }

    munin::plugin { 'munin_stats': }

    define anode($ip_address = $name, $load_warning = 0.4, $load_critical = 0.7, $cpu_system_warning = 40, $cpu_system_critical = 80, $cpu_user_warning = 40, $cpu_user_critical = 80, $cpu_iowait_warning = 60, $cpu_iowait_critical = 80, $mem_app_warning = 0.7, $mem_app_critical = 0.95) {
      file { "/etc/munin/munin-conf.d/node-${name}.conf":
        content => template('munin/node.conf'),
        require => Package['munin']
      }
    }

  }

  # node is a reserved work :-(
  class anode {

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

    class default_plugins {

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

    include munin::anode::tiger
  }

  define plugin($ensure = 'present', $script_path = '/usr/share/munin/plugins', $script = '', $config = '', $source = '') {
    include munin::anode
	  debug ( "munin_plugin: name=$name, ensure=$ensure, script_path=$script_path" )

    $real_source = $source ? {
      true => [ "puppet:///modules/munin/plugins/$name", "puppet:///files/munin/plugins/$name" ],
      default => $source
    }

	  $plugin = "/etc/munin/plugins/$name"
	  $plugin_conf = "/etc/munin/plugin-conf.d/$name.conf"

    if $real_source != '' {
      file { "/usr/local/share/munin/plugins/$name":
        ensure => $ensure,
        source => $real_source,
        mode => 755,
        before => File[$plugin]
      }

      $real_script_path = '/usr/local/share/munin/plugins'
    } else {
      $real_script_path = $script_path
    }

	  case $ensure {
		  'absent': {
			  debug ( "munin_plugin: suppressing $plugin" )
			  file { $plugin:
			    ensure => absent,
				  require => Package['munin-node'],
				  notify => Service['munin-node']
			  }
		  }
		  default: {
        case $script {
          '': {
            $plugin_src = $ensure ? { 'present' => $name, default => $ensure }
          }
          default: {
            $plugin_src = $script
          }
        }
		    debug ( "munin_plugin: making $plugin using src: $plugin_src" )

		    file { $plugin:
          ensure => "$real_script_path/${plugin_src}",
	        require => Package['munin-node'],
	        notify => Service['munin-node'],
        }
      }
    }

    case $config {
	    '': {
		    debug("no config for $name")
        file { $plugin_conf: ensure => absent }
      }
      default: {
	      case $ensure {
		      absent: {
			      debug("removing config for $name")
			      file { $plugin_conf:
				      ensure => absent,
              require => Package["munin-node"],
    		      notify => Service["munin-node"]
			      }
		      }
		      default: {
			      debug("creating $plugin_conf")
			      file { $plugin_conf:
              content => "[${name}]\n$config\n",
		          mode => 0644, owner => root, group => root,
              require => Package["munin-node"],
              notify => Service["munin-node"]
	          }
          }
        }
      }
    }
  }

}

class munin::snmp {
  file { '/usr/local/sbin/munin-snmp-host':
    source => "puppet:///munin/munin-snmp-host.rb",
    mode => 755
  }

  # sudo /usr/sbin/munin-node-configure --snmp=HOST | grep "yes" | awk '{ print $1 }' | sed 's/snmp__//'
  define host($plugins = []) {
    $plugin_names = join($plugins, ' ')
    exec { "munin-snmp-host-$name":
      command => "munin-snmp-host create $name $plugin_names",
      unless => "munin-snmp-host check $name $plugin_names",
	    require => [Package['munin-node'], File['/usr/local/sbin/munin-snmp-host']],
	    notify => Service['munin-node']
    }
  }
}

class munin::anode::tiger {
  if $tiger_enabled {
    tiger::ignore { "munin_node": }
  }
}

define munin::http::plugin($url) {
  munin::plugin { $name:
    config => "env.url $url",
    source => "puppet:///modules/munin/plugins/http_wrapper",
  }
}
