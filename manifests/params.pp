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

  $slaves_target   = '/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml'
  $slaves_template = 'dns/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml.erb'
  $tsigs_target    = '/etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml'
  $tsigs_template  = 'dns/etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml.erb'
  $ip_addresses    = [$::ipaddress]
  $nsid            = $::fqdn
  $identity        = $::fqdn

}
