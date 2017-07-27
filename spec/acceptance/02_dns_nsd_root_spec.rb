# frozen_string_literal: true

require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'apply'
  describe 'nsd class' do
    ipaddress = fact('ipaddress')
    context 'root' do
      it 'is_expected.to work with no errors' do
        pp = <<-EOS
    class {'::dns':
      daemon => 'nsd',
      remotes => {
        'lax.xfr.dns.icann.org' => {
          'address4' => '192.0.32.132'
        },
        'iad.xfr.dns.icann.org' => {
          'address4' => '192.0.47.132'
        },
      },
      zones => {
        '.' => {
          signed   => true,
          masters  => ['lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'],
          zonefile => 'root'
        },
        'arpa.' => {
          masters  => ['lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org']
        },
        'root-servers.net.' => {
          masters  => ['lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org']
        }
      }
    }
        EOS
        execute_manifest(pp, catch_failures: true)
        execute_manifest(pp, catch_failures: true)
        expect(execute_manifest(pp, catch_failures: true).exit_code).to eq 0
        # sleep to allow zone transfer (value probably to high)
        sleep(10)
      end
      describe service('nsd') do
        it { is_expected.to be_running }
      end
      describe port(53) do
        it { is_expected.to be_listening }
      end
      describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), if: os[:family] == 'ubuntu' do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command('nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf'), if: os[:family] == 'freebsd' do
        its(:stdout) { is_expected.to match %r{} }
      end
      describe command("dig +short soa . @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
      describe command("dig +short soa arpa. @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
      describe command("dig +short soa root-servers.net. @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
      end
    end
  end
end
