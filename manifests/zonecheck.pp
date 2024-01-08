# == Class: dns::zonecheck
#
# === Parameters:
#
# $enable::        true
# $syslog_level::  'error'
# $version::       'latest'
# $provider::      'pip3'

class dns::zonecheck (
  Boolean           $enable            = true,
  Tea::Syslog_level $syslog_level      = 'error',
  String            $version           = 'latest',
  String            $provider          = 'pip',
) {
  include dns
  $zones             = $dns::zones
  $ip_addresses      = $dns::ip_addresses
  $masters           = $dns::default_masters
  $provide_xfrs      = $dns::default_provide_xfrs
  $remotes           = $dns::remotes
  if $dns::default_tsig_name in $dns::tsigs {
    $tsig = {
      'algo' => 'hmac-sha256',
      'name' => $dns::default_tsig_name,
      'data' => $dns::tsigs[$dns::default_tsig_name]['data'],
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
  if $enable {
    package { 'zonecheck':
      ensure   => $version,
      provider => $provider,
    }
  }
  if $facts['kernel'] != 'FreeBSD' {
    include python
  }
  file { '/usr/local/etc/zone_check.conf':
    ensure  => file,
    content => template('dns/usr/local/etc/zone_check.conf.erb'),
  }
  if ! $enable {
    file { '/etc/puppetlabs/facter/facts.d/zone_status.txt':
      ensure  => file,
      content => 'zone_status_errors=false';
    }
  }
  cron { '/usr/local/bin/zonecheck':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts ${verbose}",
    minute  => '*/15',
  }
}
