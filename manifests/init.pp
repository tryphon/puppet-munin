import "common" # require concatenated_file defines

class munin {

  class server {
    package { munin: ensure => latest }

    if $debian::lenny {
      include apt::backports
      apt::preferences { munin:
        package => munin, 
        pin => "release a=lenny-backports",
        priority => 999,
        before => Package[munin]
      }
    }

    concatenated_file { "/etc/munin/munin.conf":
      dir => "/etc/munin/conf.d",
      require => Package[munin]
    }

    concatenated_file_source { "00munin.conf.header":
      dir    => "/etc/munin/conf.d",
      source => "puppet:///munin/munin.conf.header"
    }

    concatenated_file_source { "munin.conf.local":
      dir    => "/etc/munin/conf.d",
      source => "puppet:///files/munin/munin.conf"
    }

    # munin user can't create the log files and
    # munin tools can fail when log file is missing
    file { [ "/var/log/munin/munin-update.log", 
      "/var/log/munin/munin-graph.log", 
      "/var/log/munin/munin-html.log", 
      "/var/log/munin/munin-limits.log" ] :
      ensure => present,
      owner => munin,
      group => adm,
      require => Package[munin]
    }

    # TODO squeeze munin use /var/cache/munin/www
    file { "/var/www/munin":
      ensure => directory,
      owner => munin,
      group => munin,
      require => Package[munin]
    }

    backup::model { munin: }
  }

  # node is a reserved work :-(
  class anode {

    package { munin-node: ensure => latest }

    if $debian::lenny {
      include apt::backports
      apt::preferences { munin-node:
        package => munin-node, 
        pin => "release a=lenny-backports",
        priority => 999,
        before => Package["munin-node"]
      }
    }

    service { munin-node:
      ensure    => running,
      subscribe => [Package[munin-node], File["/etc/munin/munin-node.conf"]]
    }
    file { "/etc/munin/munin-node.conf":
      require => Package[munin-node]
    }

    # Directory to store local plugins
    file { ["/usr/local/share/munin", "/usr/local/share/munin/plugins"]:
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
        require => Package["munin-node"]
      }
      
    }

    include munin::anode::tiger

  }

  define plugin($ensure = "present", $script_path = "/usr/share/munin/plugins", $script = '', $config = '', $source = '') {
    include munin::anode
	  debug ( "munin_plugin: name=$name, ensure=$ensure, script_path=$script_path" )

    $real_source = $source ? {
      true => [ "puppet:///munin/plugins/$name", "puppet:///files/munin/plugins/$name" ],
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

      $real_script_path = "/usr/local/share/munin/plugins"
    } else {
      $real_script_path = $script_path
    }

	  case $ensure {
		  "absent": {
			  debug ( "munin_plugin: suppressing $plugin" )
			  file { $plugin:
			    ensure => absent,
				  require => Package["munin-node"],
				  notify => Service["munin-node"]
			  }
		  }
		  default: {
        case $script {
          '': {
            $plugin_src = $ensure ? { "present" => $name, default => $ensure }
          }
          default: {
            $plugin_src = $script
          }
        }
		    debug ( "munin_plugin: making $plugin using src: $plugin_src" )
        
		    file { $plugin:
          ensure => "$real_script_path/${plugin_src}",
	        require => Package["munin-node"],
	        notify => Service["munin-node"],
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

class munin::anode::tiger {
  if $tiger_enabled {
    tiger::ignore { "munin_node": }
  }
}
