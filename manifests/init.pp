# @summary Using custom types until next stdlib release
# @param default_tsig_name the default tsig key
# @param default_masters the list of default masters
# @param default_provide_xfrs the list of cfr servers
# @param default_ipv4 the default ipv4 adress
# @param default_ipv6 the default ipv4 adress
# @param server_count how many daemons to start
# @param daemon the daemon to configure
# @param nsid the NSID string
# @param identity The chaos identity string
# @param ip_addresses List of addresses to bind to
# @param imports List of import tags
# @param exports List of export tags
# @param ensure The ensure parameter
# @param port The poirt to listen on
# @param zones The list of zones to configure
# @param files list of zone files to configure
# @param tsigs List of tsigs to configure
# @param remotes hash of remotes to configure
# @param reject_private_ip indicate if private ip's are allowed as default
# @param monitor_class The monitoring class in use
# @param required_services A list of required services to manage before the daemon
#
class dns (
  Pattern[/^(present|absent)$/] $ensure               = 'present',
  String                        $default_tsig_name    = 'NOKEY',
  Array[String]                 $default_masters      = [],
  Array[String]                 $default_provide_xfrs = [],
  Stdlib::IP::Address::V4       $default_ipv4         = $facts['networking']['ip'],
  Stdlib::IP::Address::V6       $default_ipv6         = $facts['networking']['ip6'],
  Dns::Daemon                   $daemon               = 'knot',
  String                        $nsid                 = $facts['networking']['fqdn'],
  String                        $identity             = $facts['networking']['fqdn'],
  Array[Stdlib::IP::Address]    $ip_addresses         = [$facts['networking']['ip']],
  Array[String]                 $imports              = [],
  Array[String]                 $exports              = [],
  Tea::Port                     $port                 = 53,
  Hash[String, Dns::Zone]       $zones                = {},
  Hash                          $files                = {},
  Hash                          $tsigs                = {},
  Hash                          $remotes              = {},
  Boolean                       $reject_private_ip    = true,
  Optional[String]              $monitor_class        = undef,
  Array[String]                 $required_services    = [],
  Optional[Integer[1,256]]      $server_count         = undef,
) {
  $_default_ipv4 =  ($reject_private_ip and $default_ipv4 =~ Tea::Rfc1918) ? {
    true    => undef,
    default => $default_ipv4,
  }
  $_default_ipv6 =  ($reject_private_ip and $default_ipv6 =~ Pattern[/(?i:^fe80:)/]) ? {
    true    => undef,
    default => $default_ipv6,
  }
  $_server_count = $server_count.lest || { max($facts['processors']['count'] - 3, 1) }
  if $ensure == 'present' {
    if $daemon == 'nsd' {
      $nsd_enable  =  true
      $knot_enable =  false
      file { '/usr/local/bin/dns-control':
        ensure => link,
        target => '/usr/sbin/nsd-control',
      }
    } else {
      $nsd_enable  =  false
      $knot_enable =  true
      file { '/usr/local/bin/dns-control':
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
    $reduce_store.merge({ $zone => $config })
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
      dns::tsig { $_export_tsig:
        algo     => pick($tsigs[$default_tsig_name]['algo'], 'hmac-sha256'),
        data     => $tsigs[$default_tsig_name]['data'],
        key_name => $default_tsig_name,
        tag      => $export,
      }
    } else {
      $_export_tsig      = undef
    }
    dns::remote { "dns__export_${export}_${facts['fqdn']}":
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
      class { 'opendnssec':
        default_tsig_name    => $default_tsig_name,
        default_masters      => $default_masters,
        default_provide_xfrs => $default_provide_xfrs,
        tsigs                => $tsigs,
        zones                => $zones,
        remotes              => $remotes,
      }
    } else {
      class { 'nsd':
        enable               => $nsd_enable,
        ip_addresses         => $ip_addresses,
        server_count         => $_server_count,
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
      class { 'knot':
        enable               => $knot_enable,
        ip_addresses         => $ip_addresses,
        server_count         => $_server_count,
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
        Service <| title == $knot::service_name |> {
          before => Service[$nsd::service_name]
        }
      } else {
        Service <| title == $nsd::service_name |> {
          before => Service[$knot::service_name]
        }
      }
    }
  }
  unless $required_services.empty {
    Service[$required_services] -> Service[$daemon]
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
