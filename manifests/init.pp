class munin {
  backup::model { 'munin': }

  munin::plugin { 'munin_stats': }

  # node is a reserved work :-(
}
