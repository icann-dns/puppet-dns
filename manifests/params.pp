#
#
class dns::params {
  $daemon = $facts['kernel'] ? {
    'FreeBSD' => 'nsd',
    default   => $facts['lsbdistcodename'] ? {
      'precise' => 'nsd',
      default   => 'knot',
    }
  }
  if $facts['processorcount'] + 0  > 3 {
    $server_count = Integer($facts['processorcount'] - 3)
  } else {
    $server_count = 1
  }
  $default_ipv4 = $facts['networking']['ip']
  $default_ipv6 = $facts['networking']['ip6']
  $ip_addresses = [$facts['ipaddress']]
  $nsid         = $facts['fqdn']
  $identity     = $facts['fqdn']
}
