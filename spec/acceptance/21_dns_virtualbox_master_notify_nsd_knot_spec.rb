# frozen_string_literal: true

require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'agent' && ENV['VIRTUALBOX'] == 'yes'
  describe 'knot class' do
    context 'test notifies nsd -> knot' do
      dnsmaster    = find_host_with_role('dnsmaster')
      dnsmaster_ip = '10.255.1.3'
      dnsslave     = find_host_with_role('dnsslave')
      dnsslave_ip  = '10.255.1.4'
      example_zone = <<EOS
example.com. 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600
example.com. 86400 IN NS a.iana-servers.net.
example.com. 86400 IN NS b.iana-servers.net.
EOS
      dnsmaster_pp = <<-EOS
      class {'::dns':
        daemon  => 'nsd',
        ip_addresses => ['#{dnsmaster_ip}'],
        reject_private_ip => false,
        imports => ['nofiy_test'],
        zones   => {
          'example.com' => {},
        },
        files => {
          'example.com' => {
            'content' => '#{example_zone}',
          }
        },
      }
      EOS
      dnsslave_pp = <<-EOS
      class {'::dns':
        daemon  => 'knot',
        ip_addresses => ['#{dnsslave_ip}'],
        default_ipv4 => '#{dnsslave_ip}',
        reject_private_ip => false,
        exports => ['nofiy_test'],
        default_tsig_name => '#{dnsslave}-test',
        tsigs    => {
          '#{dnsslave}-test' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          },
        },
        remotes => {
          'top_server' => {
            'address4'  => '#{dnsmaster_ip}',
          }
        },
        zones   => {
          'example.com' => { 'masters' => ['top_server'] },
        },
      }
      EOS
      it 'run puppet a bunch of times' do
        execute_manifest_on(dnsmaster, dnsmaster_pp, catch_failures: true)
        execute_manifest_on(dnsslave, dnsslave_pp, catch_failures: true)
        execute_manifest_on(dnsmaster, dnsmaster_pp, catch_failures: true)
      end
      it 'clean puppet run on dns top' do
        expect(execute_manifest_on(dnsmaster, dnsmaster_pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns dnsslave' do
        expect(execute_manifest_on(dnsslave, dnsslave_pp, catch_failures: true).exit_code).to eq 0
      end
      describe service('nsd'), node: dnsmaster do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsmaster do
        it { is_expected.to be_listening }
      end
      describe service('knot'), node: dnsslave do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsslave do
        it { is_expected.to be_listening }
      end
      describe command("dig +short soa example.com. @#{dnsmaster_ip}"), node: dnsmaster do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600},
          )
        end
      end
      describe command("dig +short soa example.com. @#{dnsslave_ip}"), node: dnsslave do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600},
          )
        end
      end
      describe command('sed -i \'s/1/2/\' /var/lib/nsd/zone/example.com'), node: dnsmaster do
        its(:exit_status) { is_expected.to eq 0 }
      end
      describe command('service nsd restart'), node: dnsmaster do
        its(:exit_status) { is_expected.to eq 0 }
      end
      describe command("dig +short soa example.com. @#{dnsmaster_ip}"), node: dnsmaster do
        let(:pre_command) { 'sleep 5'  }

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 2 7200 3600 1209600 3600},
          )
        end
      end
      describe command("dig +short soa example.com. @#{dnsslave_ip}"), node: dnsslave do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 2 7200 3600 1209600 3600},
          )
        end
      end
    end
  end
end
