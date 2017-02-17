#
#
class dns::params {
  $daemon = $::kernel ? {
    'FreeBSD' => 'nsd',
    default   => $::lsbdistcodename ? {
      'precise' => 'nsd',
      default   => 'knot',
    }
  }
  #We add 0 to cast string to int
  if $::processorcount + 0  > 3 {
    $server_count = $::processorcount - 3
  } else {
    $server_count = 1
  }
  $default_ipv4 = $::networking['ip']
  $default_ipv6 = $::networking['ip6']
  $ip_addresses = [$::ipaddress]
  $nsid         = $::fqdn
  $identity     = $::fqdn
}
