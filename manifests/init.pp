# == Class: dns
#
# Using custom types untill next stdlib release
class dns (
  Pattern[/^(nsd|knot)$/]                 $daemon = $::dns::params::daemon,
  Tea::Absolutepath                $slaves_target = $::dns::params::slaves_target,
  Tea::Absolutepath                 $tsigs_target = $::dns::params::tsigs_target,
  String                                    $nsid = $::dns::params::nsid,
  String                                $identity = $::dns::params::identity,
  Array[Tea::Ip_address]            $ip_addresses = $::dns::params::ip_addresses,
  Boolean                                 $master = false,
  String                                $instance = 'default',
  Pattern[/^(present|absent)$/]           $ensure = 'present',
  Boolean                       $enable_zonecheck = true,
  Hash[String, Dns::Zone]                  $zones = {},
  Hash                                     $files = {},
  Hash                                      $tsig = {},
  Hash[String, Dns::Tsig]                  $tsigs = {},
  Hash[String, Dns::Server]              $servers = {},
  Optional[String]             $default_tsig_name = undef,
  Boolean                          $enable_nagios = false,
) inherits dns::params {
  if ! empty($tsig) {
    deprecation(
      'tsig', 'Please use the Tsig array and the default tsig name instead'
    )
  }
  class { '::dns::zonecheck':
    enable       => $enable_zonecheck,
    ip_addresses => $ip_addresses,
    zones        => $zones,
    tsig         => $tsig,
  }

  $slaves_template = 'dns/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml.erb'
  $tsigs_template  = 'dns/etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml.erb'

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
  if $master {
    #these come from the custom facts dir
    $slave_tsigs     = $::dns_slave_tsigs
    $slave_addresses = $::dns_slave_addresses
    concat{$tsigs_target:}
    concat::fragment{
      "dns_slave_tsigs_yaml_${::fqdn}":
        target  => $tsigs_target,
        content => "dns_slave_tsigs:\n",
        order   => '01',
    }
    Concat::Fragment <<| tag == "dns::${instance}_slave_tsigs" |>>
    concat{$slaves_target:}
    concat::fragment{
      "dns_slave_addresses_yaml_${::fqdn}":
        target  => $slaves_target,
        content => "dns_slave_addresses:\n",
        order   => '01',
    }
    Concat::Fragment <<| tag == "dns::${instance}_slave_interface_yaml" |>>
  } else {
    $slave_tsigs     = {}
    $slave_addresses = {}
    @@concat::fragment{ "dns_slave_tsig_yaml_${::fqdn}":
      target  => $tsigs_target,
      tag     => "dns::${instance}_slave_tsigs",
      content => template($tsigs_template),
      order   => '10',
    }
    @@concat::fragment{ "dns_slave_addresses_yaml_${::fqdn}":
      target  => $slaves_target,
      tag     => "dns::${instance}_slave_interface_yaml",
      content => template($slaves_template),
      order   => '10',
    }
  }
  #We add 0 to cast string to int
  if $::processorcount + 0  > 3 {
    $server_count = $::processorcount - 3
  } else {
    $server_count = 1
  }

  if $ensure == 'present' {
    class { '::nsd':
      enable          => $nsd_enable,
      ip_addresses    => $ip_addresses,
      tsigs           => $slave_tsigs,
      slave_addresses => $slave_addresses,
      #zones           => $zones,
      tsig            => $tsig,
      server_count    => $server_count,
      files           => $files,
      nsid            => $nsid,
      identity        => $identity,
    }
    class { '::knot':
      enable          => $knot_enable,
      ip_addresses    => $ip_addresses,
      tsigs           => $slave_tsigs,
      slave_addresses => $slave_addresses,
      #zones           => $zones,
      tsig            => $tsig,
      server_count    => $server_count,
      files           => $files,
      nsid            => $nsid,
      identity        => $identity,
    }
  }
  if $enable_nagios {
    $_ip_addresses_list = join($ip_addresses, ' ')

    $zones.each |String $zone, Hash $config| {
      if has_key($config, 'masters') {
        $_masters = flatten($config['masters'].map |String $master| {
          if ! has_key($servers, $master) {
            fail(
              "Dns::Server[${master}] configured for ${zone} but does not exist"
            )
          }
          delete_undef_values(
            [$servers[$master]['address4'], $servers[$master]['address6']]
          )
          #$servers[$master]['address4']
        })
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
  }
}
