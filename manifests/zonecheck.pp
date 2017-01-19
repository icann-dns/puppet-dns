# == Class: dns::zonecheck
#
class dns::zonecheck (
  Boolean                 $enable       = true,
  String                  $version      = '1.0.14',
  Tea::Syslog_level       $syslog_level = 'error',
  Array[Tea::Ip_address]  $ip_addresses = [],
  Hash[String, Dns::Zone] $zones        = {},
  Hash                    $tsig         = {},
) {
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
