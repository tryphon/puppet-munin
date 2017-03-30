define munin::http::plugin($url) {
  munin::plugin { $name:
    config => "env.url $url",
    source => "puppet:///modules/munin/plugins/http_wrapper",
  }
}
