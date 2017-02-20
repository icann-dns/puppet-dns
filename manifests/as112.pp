# dns::as112
#
class dns::as112 (
  Pattern[/^(nsd|knot)$/] $daemon = $::dns::params::daemon,
) inherits dns::params {
  if $daemon == 'nsd' {
    class { '::knot': enable => false }
    class { '::nsd::as112': }
  } else {
    class { '::nsd': enable => false }
    class { '::knot::as112': }
  }
}
