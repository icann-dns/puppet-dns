require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'agent'
  describe 'basic master (knot) slave (nsd) config' do
    context 'defaults' do
      in_addr_zones = [
        'in-addr.arpa',
        'in-addr-servers.arpa',
      ]
      ip6_zones = [
        'ip6.arpa',
        'ip6-servers.arpa',
      ]
      zones = [ 
        'mcast.net',
        'as112.arpa',
        'example.com',
        'example.edu',
        'example.net',
        'example.org',
        'ipv4only.arpa',
        '224.in-addr.arpa',
        '225.in-addr.arpa',
        '226.in-addr.arpa',
        '227.in-addr.arpa',
        '228.in-addr.arpa',
        '229.in-addr.arpa',
        '230.in-addr.arpa',
        '231.in-addr.arpa',
        '232.in-addr.arpa',
        '233.in-addr.arpa',
        '234.in-addr.arpa',
        '235.in-addr.arpa',
        '236.in-addr.arpa',
        '237.in-addr.arpa',
        '238.in-addr.arpa',
        '239.in-addr.arpa'
      ]
      dnsmaster         = find_host_with_role('dnsmaster')
      dnsmaster_ip      = fact_on(dnsmaster, 'ipaddress')
      slave             = find_host_with_role('slave')
      slave_ip          = fact_on(slave, 'ipaddress')
      hiera_dir         = '/etc/puppetlabs/code/environments/production/hieradata'
      pp                = 'class { \'::dns\': }'
      common_hiera = <<EOS
---
dns::zones:
  #{in_addr_zones.join(": {}\n  ")}: {}
  #{ip6_zones.join(": {}\n  ")}: {}
  #{zones.join(": {}\n  ")}: {}

EOS
      dnsmaster_hiera = <<EOF
---
dns::imports: ['top_layer']
dns::daemon: knot
dns::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
dns::default_masters:
- lax.xfr.dns.icann.org
- iad.xfr.dns.icann.org

EOF
      slave_hiera = <<EOF
---
dns::daemon: nsd
dns::exports: ['top_layer']
dns::default_tsig_name: #{slave}-test
dns::tsigs:
  #{slave}-test:
    data: qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0=
dns::remotes:
  #{dnsmaster}:
    address4: #{dnsmaster_ip}
dns::default_masters:
- #{dnsmaster}

EOF
      create_remote_file(master, "#{hiera_dir}/common.yaml", common_hiera)
      on(master, "chmod +r #{hiera_dir}/common.yaml")
      on(master, "mkdir #{hiera_dir}/nodes/")
      on(master, "chmod +rx #{hiera_dir}/nodes/")
      create_remote_file(master, "#{hiera_dir}/nodes/#{dnsmaster}.yaml", dnsmaster_hiera)
      on(master, "chmod +r #{hiera_dir}/nodes/#{dnsmaster}.yaml")
      create_remote_file(master, "#{hiera_dir}/nodes/#{slave}.yaml", slave_hiera)
      on(master, "chmod +r #{hiera_dir}/nodes/#{slave}.yaml")

      it 'run puppet a bunch of times' do
        execute_manifest_on(dnsmaster, pp, catch_failures: true)
        execute_manifest_on(slave, pp, catch_failures: true)
        execute_manifest_on(dnsmaster, pp, catch_failures: true)
        execute_manifest_on(slave, pp, catch_failures: true)
        execute_manifest_on(dnsmaster, pp, catch_failures: true)
      end
      it 'clean puppet run on dns master' do
        expect(execute_manifest_on(dnsmaster, pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns slave' do
        expect(execute_manifest_on(slave, pp, catch_failures: true).exit_code).to eq 0
      end
      # give a bit of time for all the zones to transfer
      it 'sleep for 2 minutes to allow tranfers to occur' do
        sleep(120)
      end
      describe service('knot'), node: dnsmaster do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsmaster do
        it { is_expected.to be_listening }
      end
      describe service('nsd'), node: slave do
        it { is_expected.to be_running }
      end
      describe port(53), node: slave do
        it { is_expected.to be_listening }
      end
      describe command('knotc -c /etc/knot/knot.conf checkconf || cat /etc/knot/knot.conf'), if: os[:family] == 'ubuntu', node: dnsmaster do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('knotc -c /usr/local/etc/knot/knot.conf checkconf || cat /usr/local/etc/knot/knot.conf'), if: os[:family] == 'freebsd', node: dnsmaster do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), if: os[:family] == 'ubuntu', node: slave do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf'), if: os[:family] == 'freebsd', node: slave do
        its(:stdout) { is_expected.to match %r{} }
      end
      in_addr_zones.each do |zone|
        soa_match = %r{b.in-addr-servers.arpa. nstld.iana.org.}
        describe command("dig +short soa #{zone}. @#{slave_ip}"), node: slave do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match soa_match }
        end
      end
      ip6_zones.each do |zone|
        soa_match = %r{b.ip6-servers.arpa. nstld.iana.org.}
        describe command("dig +short soa #{zone}. @#{slave_ip}"), node: slave do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match soa_match }
        end
      end
      zones.each do |zone|
        soa_match = %r{sns.dns.icann.org. noc.dns.icann.org.}
        describe command("dig +short soa #{zone}. @#{slave_ip}"), node: slave do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match soa_match }
        end
      end
    end
  end
end
