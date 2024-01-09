# frozen_string_literal: true

require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'agent'
  describe 'basic master (nsd) dnsedge (knot) config' do
    context 'defaults' do
      dnstop     = find_host_with_role('dnstop')
      dnstop_ip  = fact_on(dnstop, 'ipaddress')
      dnsedge    = find_host_with_role('dnsedge')
      dnsedge_ip = fact_on(dnsedge, 'ipaddress')
      master_pp  = <<EOS
  class { '::dns':
    imports  => ['acceptance_test'],
    daemon   => 'nsd',
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
      dnsedge_pp = <<EOS
  class { '::dns':
    exports  => ['acceptance_test'],
    daemon   => 'knot',
    default_tsig_name => '#{dnsedge}-test',
    tsigs    => {
      '#{dnsedge}-test' => {
        'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
      },
    },
    remotes  => {
      '#{dnstop}' => {
        'address4' => '#{dnstop_ip}',
      },
    },
    zones    => {
      '.' => {
        'signed' => true,
        'masters' => [ #{dnstop} ],
        'zonefile' => 'root',
      },
      'root-servers.net.' => {
        'signed' => true,
        'masters' => [ #{dnstop} ],
      },
      'arpa.' => {
        'signed' => true,
        'masters' => [ #{dnstop} ],
      },
    },
  }
EOS

      it 'run puppet a bunch of times' do
        execute_manifest_on(dnstop, master_pp, catch_failures: true)
        execute_manifest_on(dnsedge, dnsedge_pp, catch_failures: true)
        execute_manifest_on(dnstop, master_pp, catch_failures: true)
      end
      it 'clean puppet run on dns master' do
        expect(execute_manifest_on(dnstop, master_pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns dnsedge' do
        expect(execute_manifest_on(dnsedge, dnsedge_pp, catch_failures: true).exit_code).to eq 0
      end
      describe service('knot'), node: dnsedge do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsedge do
        it { is_expected.to be_listening }
      end
      describe service('nsd'), node: dnstop do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnstop do
        it { is_expected.to be_listening }
      end
      describe command('knotc -c /etc/knot/knot.conf checkconf || cat /etc/knot/knot.conf'), node: dnsedge do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), node: dnstop do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command("dig +short soa . @#{dnsedge_ip}"), node: dnsedge do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
      describe command("dig +short soa root-servers.net. @#{dnsedge_ip}"), node: dnsedge do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
      describe command("dig +short soa arpa. @#{dnsedge_ip}"), node: dnsedge do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
    end
  end
end
