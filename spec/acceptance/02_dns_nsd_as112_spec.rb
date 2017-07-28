# frozen_string_literal: true

require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'apply'
  describe 'nsd class' do
    ipaddress = fact('ipaddress')
    context 'as112' do
      it 'is_expected.to work with no errors' do
        pp = <<~END
        class {'::dns': daemon => 'nsd' }
        class {'::dns::as112': }
        END
        execute_manifest(pp, catch_failures: true)
        execute_manifest(pp, catch_failures: true)
        expect(execute_manifest(pp, catch_failures: true).exit_code).to eq 0
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
      describe command("dig +short soa empty.as112.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{blackhole.as112.arpa. noc.dns.icann.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 10.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 16.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 17.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 18.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 19.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 20.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 21.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 22.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 23.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 24.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 25.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 26.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 27.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 28.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 29.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 30.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 31.172.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 168.192.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
      describe command("dig +short soa 254.169.in-addr.arpa @#{ipaddress}") do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
      end
    end
  end
end
