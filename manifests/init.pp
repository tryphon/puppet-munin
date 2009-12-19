import "common" # require concatenated_file defines

class munin {

  class server {
    package { munin: }

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

  }

  # node is a reserved work :-(
  class anode {

    package { munin-node: ensure => installed }

    service { munin-node:
      ensure    => running,
      subscribe => [Package[munin-node], File["/etc/munin/munin-node.conf"]]
    }
    file { "/etc/munin/munin-node.conf":
      require => Package[munin-node]
    }

  }


  define plugin ($ensure = "present", $script_path = "/usr/share/munin/plugins", $script = '', $config = '') {
	  debug ( "munin_plugin: name=$name, ensure=$ensure, script_path=$script_path" )
	  $plugin = "/etc/munin/plugins/$name"

	  $plugin_conf = "/etc/munin/plugin-conf.d/$name.conf"
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
          ensure => "$script_path/${plugin_src}",
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
