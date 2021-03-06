# == Class: dns
#
# Using custom types untill next stdlib release
class dns (
  Optional[String]              $default_tsig_name    = 'NOKEY',
  Array[String]                 $default_masters      = [],
  Array[String]                 $default_provide_xfrs = [],
  Optional[Stdlib::IP::Address::V4] $default_ipv4     = $::dns::params::default_ipv4,
  Optional[Stdlib::IP::Address::V6] $default_ipv6     = $::dns::params::default_ipv6,
  Integer[1,256]                $server_count         = $::dns::params::server_count,
  Dns::Daemon                   $daemon               = $::dns::params::daemon,
  String                        $nsid                 = $::dns::params::nsid,
  String                        $identity             = $::dns::params::identity,
  Array[Stdlib::IP::Address]    $ip_addresses         = $::dns::params::ip_addresses,
  Array[String]                 $imports              = [],
  Array[String]                 $exports              = [],
  Pattern[/^(present|absent)$/] $ensure               = 'present',
  Tea::Port                     $port                 = 53,
  Hash[String, Dns::Zone]       $zones                = {},
  Hash                          $files                = {},
  Hash                          $tsigs                = {},
  Hash                          $remotes              = {},
  Boolean                       $enable_nagios        = false,
  Boolean                       $reject_private_ip    = true,
  Optional[String]              $monitor_class        = undef,
) inherits dns::params {

  $_default_ipv4 =  ($reject_private_ip and $default_ipv4 =~ Tea::Rfc1918) ? {
    true    => undef,
    default => $default_ipv4,
  }
  $_default_ipv6 =  ($reject_private_ip and $default_ipv6 =~ Pattern[/(?i:^fe80:)/]) ? {
    true    => undef,
    default => $default_ipv6,
  }
  if $ensure == 'present' {
    if $daemon == 'nsd' {
      $nsd_enable  =  true
      $knot_enable =  false
      file {'/usr/local/bin/dns-control':
        ensure => link,
        target => '/usr/sbin/nsd-control',
      }
    } else {
      $nsd_enable  =  false
      $knot_enable =  true
      file {'/usr/local/bin/dns-control':
        ensure => link,
        target => '/usr/sbin/knotc',
      }
    }
  }
  # Currently nsd and knot dont support signed
  # and signed policy so we remove them
  $_zones = $zones.reduce({}) |$reduce_store, $value| {
    $zone = $value[0]
    $config = $value[1].filter |$key| { $key[0] !~ /^signe/ }
    $tmp = merge($reduce_store, {$zone => $config})
    $tmp
  }
  if $ensure == 'present' {
    $imports.each |String $import| {
      Knot::Tsig <<| tag == $import |>>
      Knot::Remote <<| tag == $import |>>
      Nsd::Tsig <<| tag == $import |>>
      Nsd::Remote <<| tag == $import |>>
    }
  }
  $exports.each |String $export| {
    if $default_tsig_name != 'NOKEY' {
      $_export_tsig      = "dns__export_${export}_${default_tsig_name}"
      dns::tsig {$_export_tsig:
        algo     => pick($tsigs[$default_tsig_name]['algo'], 'hmac-sha256'),
        data     => $tsigs[$default_tsig_name]['data'],
        key_name => $default_tsig_name,
        tag      => $export,
      }
    } else {
      $_export_tsig      = undef
    }
    dns::remote {"dns__export_${export}_${::fqdn}":
      address4  => $_default_ipv4,
      address6  => $_default_ipv6,
      tsig      => $_export_tsig,
      tsig_name => $default_tsig_name,
      port      => $port,
      tag       => $export,
    }
  }

  if $ensure == 'present' {
    if $daemon == 'opendnssec' {
      class {'::opendnssec':
        default_tsig_name    => $default_tsig_name,
        default_masters      => $default_masters,
        default_provide_xfrs => $default_provide_xfrs,
        tsigs                => $tsigs,
        zones                => $zones,
        remotes              => $remotes,
      }
    } else {
      class { '::nsd':
        enable               => $nsd_enable,
        ip_addresses         => $ip_addresses,
        server_count         => $server_count,
        nsid                 => $nsid,
        identity             => $identity,
        default_tsig_name    => $default_tsig_name,
        default_masters      => $default_masters,
        default_provide_xfrs => $default_provide_xfrs,
        files                => $files,
        tsigs                => $tsigs,
        zones                => $_zones,
        remotes              => $remotes,
        imports              => $imports,
        exports              => $exports,
      }
      class { '::knot':
        enable               => $knot_enable,
        ip_addresses         => $ip_addresses,
        server_count         => $server_count,
        nsid                 => $nsid,
        identity             => $identity,
        default_tsig_name    => $default_tsig_name,
        default_masters      => $default_masters,
        default_provide_xfrs => $default_provide_xfrs,
        files                => $files,
        tsigs                => $tsigs,
        zones                => $_zones,
        remotes              => $remotes,
        imports              => $imports,
        exports              => $exports,
      }
      # when switching from one deamon to the other we need to make sure
      # the old one is stoped before the new one starts
      if $daemon == 'nsd' {
        Service <| title == $::knot::service_name |> {
          before => Service[$::nsd::service_name]
        }
      } else {
        Service <| title == $::nsd::service_name |> {
          before => Service[$::knot::service_name]
        }
      }
    }
  }
  if $enable_nagios {
    $_ip_addresses_list = join($ip_addresses, ' ')
    $zones.each |String $zone, Hash $config| {
      if has_key($config, 'masters') {
        $_masters = flatten($config['masters'].map |String $master| {
          delete_undef_values(
            [$remotes[$master]['address4'], $remotes[$master]['address6']]
          )
        })
      } else {
        $_masters = flatten($default_masters.map |String $master| {
          delete_undef_values(
            [$remotes[$master]['address4'], $remotes[$master]['address6']]
          )
        })
      }
      if ! empty($_masters) {
        $master_check_args = join($_masters, ' ')
        @@nagios_service{ "${::fqdn}_DNS_ZONE_MASTERS_${zone}":
          ensure              => present,
          use                 => 'generic-service',
          host_name           => $::fqdn,
          service_description => "DNS_ZONE_MASTERS_${zone}",
          check_command       => "check_nrpe_args!check_dns!${zone}!${master_check_args}!${_ip_addresses_list}",
        }
      }
    }
  }
  if $monitor_class {
    class { $monitor_class:
      tsigs                => $tsigs,
      remotes              => $remotes,
      zones                => $zones,
      default_masters      => $default_masters,
      default_provide_xfrs => $default_provide_xfrs,
      default_tsig_name    => $default_tsig_name,
    }
  }
}
