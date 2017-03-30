define munin::plugin($ensure = 'present', $script_path = '/usr/share/munin/plugins', $script = '', $config = '', $source = '') {
  include munin::anode
        debug ( "munin_plugin: name=$name, ensure=$ensure, script_path=$script_path" )

  $real_source = $source ? {
    true    => [ "puppet:///modules/munin/plugins/$name", "puppet:///files/munin/plugins/$name" ],
    default => $source
  }

        $plugin = "/etc/munin/plugins/$name"
        $plugin_conf = "/etc/munin/plugin-conf.d/$name.conf"

  if $real_source != '' {
    file { "/usr/local/share/munin/plugins/$name":
      ensure => $ensure,
      source => $real_source,
      mode   => '0755',
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
      	    ensure  => absent,
            require => Package["munin-node"],
  	    notify  => Service["munin-node"]
      	  }
      	}
        default: {
          debug("creating $plugin_conf")
          file { $plugin_conf:
            content => "[${name}]\n$config\n",
      	    mode    => '0644',
            owner   => root,
            group   => root,
            require => Package["munin-node"],
            notify  => Service["munin-node"]
          }
        }
      }
    }
  }
}
