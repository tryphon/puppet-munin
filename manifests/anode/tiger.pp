class munin::anode::tiger($tiger_enabled = false) {
  if $tiger_enabled {
    tiger::ignore { "munin_node": }
  }
}
