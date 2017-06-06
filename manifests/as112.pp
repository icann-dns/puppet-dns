# dns::as112
#
class dns::as112 {
  include ::dns
  if $dns::daemon == 'nsd' {
    class { '::nsd::as112': }
  } else {
    class { '::knot::as112': }
  }
}
