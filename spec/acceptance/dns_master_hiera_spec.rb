require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'agent'
  describe 'basic master (knot) dnsmiddle (nsd) config' do
    context 'defaults' do
      in_addr_zones = [
        'in-addr.arpa',
        'in-addr-servers.arpa'
      ]
      ip6_zones = [
        'ip6.arpa',
        'ip6-servers.arpa'
      ]
      other_zones = [
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
      allzones = in_addr_zones + ip6_zones + other_zones
      dnstop         = find_host_with_role('dnstop')
      dnstop_ip      = fact_on(dnstop, 'ipaddress')
      dnsmiddle      = find_host_with_role('dnsmiddle')
      dnsmiddle_ip   = fact_on(dnsmiddle, 'ipaddress')
      dnsedge        = find_host_with_role('dnsedge')
      dnsedge_ip     = fact_on(dnsedge, 'ipaddress')
      hiera_dir      = '/etc/puppetlabs/code/environments/production/hieradata'
      pp             = 'class { \'::dns\': }'
      common_hiera = <<EOS
---
dns::zones:
  #{allzones.join(": {}\n  ")}: {}

EOS
      dnstop_hiera = <<EOF
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
      dnsmiddle_hiera = <<EOF
---
dns::daemon: nsd
dns::exports: ['top_layer']
dns::imports: ['mid_layer']
dns::default_tsig_name: #{dnsmiddle}-test
dns::tsigs:
  #{dnsmiddle}-test:
    data: qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0=
dns::remotes:
  #{dnstop}:
    address4: #{dnstop_ip}
dns::default_masters:
- #{dnstop}

EOF
      dnsedge_hiera = <<EOF
---
dns::daemon: nsd
dns::exports: ['mid_layer']
dns::default_tsig_name: #{dnsedge}-test
dns::tsigs:
  #{dnsedge}-test:
    data: L7WLyxJGM5X8tfmzMKdfaQt369JWxAMTmm09ZFgMTc4=
dns::remotes:
  #{dnsmiddle}:
    address4: #{dnsmiddle_ip}
dns::default_masters:
- #{dnsmiddle}

EOF
      create_remote_file(master, "#{hiera_dir}/common.yaml", common_hiera)
      on(master, "chmod +r #{hiera_dir}/common.yaml")
      on(master, "mkdir #{hiera_dir}/nodes/")
      on(master, "chmod +rx #{hiera_dir}/nodes/")
      create_remote_file(master, "#{hiera_dir}/nodes/#{dnstop}.yaml", dnstop_hiera)
      on(master, "chmod +r #{hiera_dir}/nodes/#{dnstop}.yaml")
      create_remote_file(master, "#{hiera_dir}/nodes/#{dnsmiddle}.yaml", dnsmiddle_hiera)
      on(master, "chmod +r #{hiera_dir}/nodes/#{dnsmiddle}.yaml")
      create_remote_file(master, "#{hiera_dir}/nodes/#{dnsedge}.yaml", dnsedge_hiera)
      on(master, "chmod +r #{hiera_dir}/nodes/#{dnsedge}.yaml")

      it 'run puppet a bunch of times' do
        execute_manifest_on(dnstop, pp, catch_failures: true)
        execute_manifest_on(dnsmiddle, pp, catch_failures: true)
        execute_manifest_on(dnsedge, pp, catch_failures: true)
        execute_manifest_on(dnstop, pp, catch_failures: true)
        execute_manifest_on(dnsmiddle, pp, catch_failures: true)
        execute_manifest_on(dnsedge, pp, catch_failures: true)
        execute_manifest_on(dnstop, pp, catch_failures: true)
        execute_manifest_on(dnsmiddle, pp, catch_failures: true)
      end
      it 'clean puppet run on dns master' do
        expect(execute_manifest_on(dnstop, pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns dnsmiddle' do
        expect(execute_manifest_on(dnsmiddle, pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns dnsedge' do
        execute_manifest_on(dnsedge, pp, catch_failures: true)
      end
      # give a bit of time for all the zones to transfer
      it 'sleep for 2 minutes to allow tranfers to occur' do
        sleep(120)
      end
      describe service('knot'), node: dnstop do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnstop do
        it { is_expected.to be_listening }
      end
      describe service('nsd'), node: dnsmiddle do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsmiddle do
        it { is_expected.to be_listening }
      end
      describe command('knotc -c /etc/knot/knot.conf checkconf || cat /etc/knot/knot.conf'), if: os[:family] == 'ubuntu', node: dnstop do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('knotc -c /usr/local/etc/knot/knot.conf checkconf || cat /usr/local/etc/knot/knot.conf'), if: os[:family] == 'freebsd', node: dnstop do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), if: os[:family] == 'ubuntu', node: dnsmiddle do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf'), if: os[:family] == 'freebsd', node: dnsmiddle do
        its(:stdout) { is_expected.to match %r{} }
      end
      allzones.each do |zone|
        soa_match = if in_addr_zones.include?(zone)
                      %r{b.in-addr-servers.arpa. nstld.iana.org.}
                    elsif ip6_zones.include?(zone)
                      %r{b.ip6-servers.arpa. hostmaster.icann.org.}
                    else
                      %r{sns.dns.icann.org. noc.dns.icann.org.}
                    end
        describe command("dig +short soa #{zone}. @#{dnstop_ip}"), node: dnstop do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match soa_match }
        end
        describe command("dig +short soa #{zone}. @#{dnsmiddle_ip}"), node: dnsmiddle do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match soa_match }
        end
        describe command("dig +short soa #{zone}. @#{dnsedge_ip}"), node: dnsedge do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match soa_match }
        end
      end
    end
  end
end
