# == Class: dns::zonecheck
#
class dns::zonecheck (
  Boolean                 $enable       = true,
  String                  $version      = '1.0.14',
  Tea::Syslog_level       $syslog_level = 'error',
) {
  include ::dns
  $zones        = $::dns::zones
  $ip_addresses = $::dns::ip_addresses
  $masters      = $::dns::default_masters
  $provide_xfrs = $::dns::default_provide_xfrs
  $remotes      = $::dns::remotes
  if has_key($::dns::tsigs, $::dns::default_tsig_name) {
    $tsig = {
      'algo' => 'hmac-sha256',
      'name' => $::dns::default_tsig_name,
      'data' => $::dns::tsigs[$::dns::default_tsig_name]['data'],
    }
  }
  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }
  $verbose = $syslog_level ? {
    'critical' => '',
    'error'    => '-v',
    'warn'     => '-vv',
    'info'     => '-vvv',
    'debug'    => '-vvvv',
    default    => '-v'
  }
  package {'zonecheck':
    ensure   => $version,
    provider => 'pip',
  }
  if $::kernel != 'FreeBSD' {
    include ::python
  }
  file {'/usr/local/etc/zone_check.conf':
    ensure  => $ensure,
    content => template('dns/usr/local/etc/zone_check.conf.erb'),
  }
  cron {'/usr/local/bin/zonecheck':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts ${verbose}",
    minute  => '*/15',
  }
}
