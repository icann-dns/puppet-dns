require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'agent'
  describe 'basic master (knot) slave (nsd) config' do
    context 'defaults' do
      dnsmaster    = find_host_with_role('dnsmaster')
      dnsmaster_ip = fact_on(dnsmaster, 'ipaddress')
      slave        = find_host_with_role('slave')
      slave_ip     = fact_on(slave, 'ipaddress')
      master_pp = <<EOS
  class { '::dns':
    instance => 'acceptance_test',
    master   => true,
    daemon   => 'knot',
    remotes  => {
      'lax.xfr.dns.icann.org' => {
        'address4' => '192.0.32.132',
        'address6' => '2620:0:2d0:202::132',
      },
      'iad.xfr.dns.icann.org' => {
        'address4' => '192.0.47.132',
        'address6' => '2620:0:2830:202::132',
      },
    },
    zones    => {
      '.' => {
        'signed' => true,
        'masters' => [ 'lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'],
        'zonefile' => 'root',
      },
      'root-servers.net.' => {
        'signed' => true,
        'masters' => [ 'lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'],
      },
      'arpa.' => {
        'signed' => true,
        'masters' => [ 'lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'],
      },
    },
  }
EOS
      # the key below is only to be used in here to not use it in production
      slave_pp = <<EOS
  class { '::dns':
    instance => 'acceptance_test',
    daemon   => 'knot',
    default_tsig_name => '#{slave}-test',
    tsigs    => {
      '#{slave}-test' => {
        'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
      },
    },
    remotes  => {
      '#{dnsmaster}' => {
        'address4' => '#{dnsmaster_ip}',
      },
    },
    zones    => {
      '.' => {
        'signed' => true,
        'masters' => [ #{dnsmaster} ],
        'zonefile' => 'root',
      },
      'root-servers.net.' => {
        'signed' => true,
        'masters' => [ #{dnsmaster} ],
      },
      'arpa.' => {
        'signed' => true,
        'masters' => [ #{dnsmaster} ],
      },
    },
  }
EOS

      execute_manifest_on(dnsmaster, master_pp, catch_failures: true)
      execute_manifest_on(slave, slave_pp, catch_failures: true)
      execute_manifest_on(dnsmaster, master_pp, catch_failures: true)
      execute_manifest_on(slave, slave_pp, catch_failures: true)
      execute_manifest_on(dnsmaster, master_pp, catch_failures: true)
      it 'clean puppet run on dns master' do
        expect(execute_manifest_on(dnsmaster, master_pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns slave' do
        expect(execute_manifest_on(slave, slave_pp, catch_failures: true).exit_code).to eq 0
      end
      describe service('knot'), node: dnsmaster do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsmaster do
        it { is_expected.to be_listening }
      end
      describe service('knot'), node: slave do
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
      describe command('knotc -c /etc/knot/knot.conf checkconf || cat /etc/knot/knot.conf'), if: os[:family] == 'ubuntu', node: slave do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('knotc -c /usr/local/etc/knot/knot.conf checkconf || cat /usr/local/etc/knot/knot.conf'), if: os[:family] == 'freebsd', node: slave do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command("dig +short soa . @#{slave_ip}"), node: slave do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
      describe command("dig +short soa root-servers.net. @#{slave_ip}"), node: slave do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
      describe command("dig +short soa arpa. @#{slave_ip}"), node: slave do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
    end
  end
end
