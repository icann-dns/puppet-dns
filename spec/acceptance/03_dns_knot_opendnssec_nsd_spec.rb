# frozen_string_literal: true

if ENV['BEAKER_TESTMODE'] == 'apply'
  require 'spec_helper_acceptance'
  describe 'bump in the wire' do
    dnssigner    = find_host_with_role('dnssigner')
    dnsslave     = find_host_with_role('dnsslave')
    dnsmaster_ip = fact('ipaddress')
    dnssigner_ip = fact_on(dnssigner, 'ipaddress')
    dnsslave_ip  = fact_on(dnsslave, 'ipaddress')
    example_zone = <<ZONE_CONTENT
example.com. 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600
example.com. 86400 IN NS a.iana-servers.net.
example.com. 86400 IN NS b.iana-servers.net.
ZONE_CONTENT
    context 'defaults' do
      dnsmaster_pp = <<-PUPPET_POLICY
      class {'::dns':
        daemon            => 'knot',
        ip_addresses      => ['#{dnsmaster_ip}'],
        reject_private_ip => false,
        tsigs             => {
          'test_tsig' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          }
        },
        default_tsig_name => 'test_tsig',
        remotes           => { 'dnssigner' => { 'address4' => '#{dnssigner_ip}' } },
        files             => {
          'example.com' => { 'content' => '#{example_zone}' },
        },
        zones             => {
          'example.com' => {
            'provide_xfrs' => ['dnssigner'],
          }
        },
      }
      PUPPET_POLICY
      dnssigner_pp = <<-PUPPET_POLICY
      class {'::softhsm':
        tokens => {
          'OpenDNSSEC' => {
            'pin'    => '1234',
            'so_pin' => '1234',
          }
        }
      }
      class {'::dns':
        daemon => 'opendnssec',
        ip_addresses      => ['#{dnssigner_ip}'],
        reject_private_ip => false,
        tsigs             => {
          'test_tsig' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          }
        },
        default_tsig_name => 'test_tsig',
        remotes => {
          'dnsmaster' => { 'address4' => '#{dnsmaster_ip}' },
          'dnsslave'  => { 'address4' => '#{dnsslave_ip}' },
        },
        zones         => {
          'example.com' => {
            'masters'      => ['dnsmaster'],
            'provide_xfrs' => ['dnsslave']
          }
        }
      }
      PUPPET_POLICY
      dnsslave_pp = <<-PUPPET_POLICY
      class {'::dns':
        daemon            => 'nsd',
        ip_addresses      => ['#{dnsslave_ip}'],
        reject_private_ip => false,
        tsigs             => {
          'test_tsig' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          }
        },
        default_tsig_name => 'test_tsig',
        remotes           => { 'dnssigner' => { 'address4' => '#{dnssigner_ip}' } },
        zones             => { 'example.com' => { 'masters' => ['dnssigner'] } },
      }
      PUPPET_POLICY

      it 'run without errors on dnsmaster' do
        expect(
          apply_manifest(dnsmaster_pp, catch_failures: true).exit_code,
        ).to eq 2
      end
      it 'run dnssigner twice' do
        apply_manifest_on(dnssigner, dnssigner_pp, catch_failures: true)
        expect(
          apply_manifest_on(
            dnssigner, dnssigner_pp, catch_failures: true
          ).exit_code,
        ).to eq 2
      end
      it 'run without errors on dnsslave' do
        expect(
          apply_manifest_on(
            dnsslave, dnsslave_pp, catch_failures: true
          ).exit_code,
        ).to eq 2
      end
      it 'clean run on dnsmaster' do
        expect(
          apply_manifest(dnsmaster_pp, catch_failures: true).exit_code,
        ).to eq 0
      end
      it 'clean run on dnssigner' do
        expect(
          apply_manifest_on(dnssigner, dnssigner_pp, catch_failures: true).exit_code,
        ).to eq 0
      end
      it 'clean run on dnsslave' do
        expect(
          apply_manifest_on(
            dnsslave, dnsslave_pp, catch_failures: true
          ).exit_code,
        ).to eq 0
      end
      describe service('knot') do
        it { is_expected.to be_running }
      end
      describe service('opendnssec-signer'), node: dnssigner do
        it { is_expected.to be_running }
      end
      describe service('nsd'), node: dnsslave do
        it { is_expected.to be_running }
      end
      describe port(53) do
        it { is_expected.to be_listening }
      end
      describe port(53), node: dnsslave do
        it { is_expected.to be_listening }
      end
      describe port(53), node: dnssigner do
        it { is_expected.to be_listening }
      end
      describe command(
        "dig +dnssec SOA example.com @#{dnsslave_ip}",
      ), node: dnsslave do
        its(:stdout) do
          is_expected.to match(
            %r{example.com.\s+3600\s+IN\s+SOA\ssns.dns.icann.org.\snoc.dns.icann.org.\s1},
          )
        end
        its(:stdout) { is_expected.to match(%r{\bRRSIG\b}) }
      end
      describe command(
        "dig +dnssec DNSKEY example.com @#{dnsslave_ip}",
      ), node: dnsslave do
        its(:stdout) { is_expected.to match(%r{\bDNSKEY\s+257\b}) }
        its(:stdout) { is_expected.to match(%r{\bDNSKEY\s+256\b}) }
        its(:stdout) { is_expected.to match(%r{\bRRSIG\b}) }
      end
      describe command('sed -i \'s/1/2/\' /etc/knot/zone/zone/example.com') do
        its(:exit_status) { is_expected.to eq 0 }
      end
      describe command('service knot restart') do
        its(:exit_status) { is_expected.to eq 0 }
      end
      describe command(
        "dig +dnssec SOA example.com @#{dnsslave_ip}",
      ), node: dnsslave do
        let(:pre_command) { 'sleep 5' }

        its(:stdout) do
          is_expected.to match(
            %r{example.com.\s+3600\s+IN\s+SOA\ssns.dns.icann.org.\snoc.dns.icann.org.\s2},
          )
        end
        its(:stdout) { is_expected.to match(%r{\bRRSIG\b}) }
      end
    end
  end
end
