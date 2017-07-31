# frozen_string_literal: true

require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'agent'
  describe 'knot class' do
    context 'test notifies nsd -> knot' do
      dnstop    = find_host_with_role('dnstop')
      dnstop_ip = fact_on(dnstop, 'ipaddress')
      dnsedge     = find_host_with_role('dnsedge')
      dnsedge_ip  = fact_on(dnsedge, 'ipaddress')
      example_zone = <<EOS
example.com. 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600
example.com. 86400 IN NS a.iana-servers.net.
example.com. 86400 IN NS b.iana-servers.net.
EOS
      dnstop_pp = <<-EOS
      class {'::dns':
        daemon  => 'nsd',
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
      dnsedge_pp = <<-EOS
      class {'::dns':
        daemon  => 'knot',
        exports => ['nofiy_test'],
        default_tsig_name => '#{dnsedge}-test',
        tsigs    => {
          '#{dnsedge}-test' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          },
        },
        remotes => {
          'top_server' => {
            'address4'  => '#{dnstop_ip}',
          }
        },
        zones   => {
          'example.com' => { 'masters' => ['top_server'] },
        },
      }
      EOS
      it 'run puppet a bunch of times' do
        execute_manifest_on(dnstop, dnstop_pp, catch_failures: true)
        execute_manifest_on(dnsedge, dnsedge_pp, catch_failures: true)
        execute_manifest_on(dnstop, dnstop_pp, catch_failures: true)
      end
      it 'clean puppet run on dns top' do
        expect(execute_manifest_on(dnstop, dnstop_pp, catch_failures: true).exit_code).to eq 0
      end
      it 'clean puppet run on dns dnsedge' do
        expect(execute_manifest_on(dnsedge, dnsedge_pp, catch_failures: true).exit_code).to eq 0
      end
      describe service('nsd'), node: dnstop do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnstop do
        it { is_expected.to be_listening }
      end
      describe service('knot'), node: dnsedge do
        it { is_expected.to be_running }
      end
      describe port(53), node: dnsedge do
        it { is_expected.to be_listening }
      end
      describe command("dig +short soa example.com. @#{dnstop_ip}"), node: dnstop do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600}
          )
        end
      end
      describe command("dig +short soa example.com. @#{dnsedge_ip}"), node: dnsedge do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600}
          )
        end
      end
      describe command('sed -i \'s/1/2/\' /var/lib/nsd/zone/example.com'), node: dnstop do
        its(:exit_status) { is_expected.to eq 0 }
      end
      describe command('service nsd restart'), node: dnstop do
        its(:exit_status) { is_expected.to eq 0 }
        # sleep a bit to let the transfer happen
        sleep(2)
      end
      describe command("dig +short soa example.com. @#{dnstop_ip}"), node: dnstop do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 2 7200 3600 1209600 3600}
          )
        end
      end
      describe command("dig +short soa example.com. @#{dnsedge_ip}"), node: dnsedge do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) do
          is_expected.to match(
            %r{sns.dns.icann.org. noc.dns.icann.org. 2 7200 3600 1209600 3600}
          )
        end
      end
    end
  end
end
