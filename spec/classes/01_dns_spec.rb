# frozen_string_literal: true

require 'spec_helper'

describe 'dns' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'dns.example.com' }

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) { {} }

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(
          environment: 'production',
          networking: facts[:networking].merge(
            { 'ip' => '192.0.2.1', 'ip6' => '2001:DB8::1' },
          ),
        )
      end

      let(:nsd_enable) { false }
      let(:knot_enable) { true }
      let(:dns_control) { '/usr/sbin/knotc' }
      let(:daemon) { 'knot' }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('dns') }
        # it { is_expected.to contain_class('dns::zonecheck') }
        it do
          is_expected.to contain_file('/usr/local/bin/dns-control').with(
            'ensure' => 'link',
            'target' => dns_control,
          )
        end
        it do
          is_expected.to contain_class('nsd').with(
            enable: nsd_enable,
            ip_addresses: ['192.0.2.1'],
            server_count: 1,
            nsid: 'dns.example.com',
            identity: 'dns.example.com',
            files: {},
            zones: {},
            tsigs: {},
            remotes: {},
          )
        end
        it do
          is_expected.to contain_class('knot').with(
            enable: knot_enable,
            ip_addresses: ['192.0.2.1'],
            server_count: 1,
            nsid: 'dns.example.com',
            identity: 'dns.example.com',
            files: {},
            zones: {},
            tsigs: {},
            remotes: {},
          )
        end
      end
      describe 'Change Defaults' do
        context 'nsid' do
          let(:params) { super().merge!(nsid: 'foobar') }

          it { is_expected.to compile }
          it { is_expected.to contain_class('knot').with_nsid('foobar') }
          it { is_expected.to contain_class('nsd').with_nsid('foobar') }
        end
        context 'identity' do
          let(:params) { super().merge!(identity: 'foobar') }

          it { is_expected.to compile }
          it { is_expected.to contain_class('knot').with_identity('foobar') }
          it { is_expected.to contain_class('nsd').with_identity('foobar') }
        end
        context 'ip_addresses' do
          let(:params) { super().merge!(ip_addresses: ['192.0.2.2', '2001:DB8::1']) }

          it { is_expected.to compile }
          it do
            is_expected.to contain_class('nsd').with_ip_addresses(
              ['192.0.2.2', '2001:DB8::1'],
            )
          end
          it do
            is_expected.to contain_class('knot').with_ip_addresses(
              ['192.0.2.2', '2001:DB8::1'],
            )
          end
        end
        context 'processors count larger then 3' do
          let(:facts) { super().merge(processors: { 'count' => 6 }) }

          it { is_expected.to contain_class(daemon).with_server_count(3) }
        end
        context 'processors count smaller then 2' do
          let(:facts) { super().merge(processors: { 'count' => 4 }) }

          it { is_expected.to contain_class(daemon).with_server_count(1) }
        end
        context 'exports' do
          Puppet::Util::Log.level = :debug
          Puppet::Util::Log.newdestination(:console)
          let(:params) { super().merge!(exports: ['foobar']) }

          it { is_expected.to compile }
          it do
            is_expected.to contain_dns__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.0.2.1',
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
          it do
            expect(exported_resources).to contain_nsd__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.0.2.1',
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
          it do
            expect(exported_resources).to contain_knot__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.0.2.1',
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
        end
        context 'reject_private_ip reject ipv4' do
          let(:params) do
            super().merge!(
              exports: ['foobar'],
              default_ipv4: '192.168.0.1',
            )
          end

          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nsd__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: nil,
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
          it do
            expect(exported_resources).to contain_knot__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: nil,
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
        end
        context 'reject_private_ip reject ipv6' do
          let(:params) do
            super().merge!(
              exports: ['foobar'],
              default_ipv6: 'fE80::250:56ff:feae:ae83',
            )
          end

          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nsd__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.0.2.1',
              address6: nil,
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
          it do
            expect(exported_resources).to contain_knot__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.0.2.1',
              address6: nil,
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
        end
        context 'reject_private_ip allow private addresses' do
          let(:params) do
            super().merge!(
              exports: ['foobar'],
              default_ipv4: '192.168.0.1',
              default_ipv6: 'fE80::250:56ff:feae:ae83',
              reject_private_ip: false,
            )
          end

          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nsd__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.168.0.1',
              address6: 'fE80::250:56ff:feae:ae83',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
          it do
            expect(exported_resources).to contain_knot__remote(
              'dns__export_foobar_dns.example.com',
            ).with(
              address4: '192.168.0.1',
              address6: 'fE80::250:56ff:feae:ae83',
              tsig_name: 'NOKEY',
              port: 53,
            )
          end
        end
        context 'ensure' do
          let(:params) { super().merge!(ensure: 'absent') }

          it { is_expected.to compile }
          it { is_expected.not_to contain_class('knot') }
          it { is_expected.not_to contain_class('nsd') }
        end
        context 'zones' do
          let(:params) do
            super().merge!(
              zones: {
                'example.com' => {
                  'signed' => true,
                  'masters' => ['master.example.com'],
                  'provide_xfrs' => ['slave.example.com'],
                },
              },
              remotes: {
                'master.example.com' => {
                  'address4' => '192.0.2.1',
                },
                'slave.example.com' => {
                  'address4' => '192.0.2.2',
                },
              },
            )
          end

          it { is_expected.to compile }
        end
        context 'files' do
          let(:params) do
            super().merge!(
              files: { 'test' => { 'source' => 'puppet:///modules/dns/source' } },
            )
          end

          it { is_expected.to compile }
        end
        context 'tsigs' do
          let(:params) { super().merge!(tsigs: { 'test' => { 'data' => 'aaaa' } }) }

          it { is_expected.to compile }
          it { is_expected.to contain_nsd__tsig('test') }
          it { is_expected.to contain_knot__tsig('test') }
        end
        context 'required_services' do
          let(:pre_condition) { "service { 'networking': }" }
          let(:params) { super().merge!(required_services: ['networking']) }

          it { is_expected.to compile }
        end
        context 'multiple required_services' do
          let(:pre_condition) do
            <<-EOS
            service { 'networking': }
            service { 'iptables': }
            EOS
          end
          let(:params) { super().merge!(required_services: ['networking', 'iptables']) }

          it { is_expected.to compile }
        end
      end
      describe 'check bad type' do
        context 'daemon' do
          let(:params) { super().merge!(daemon: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'daemon bad option' do
          let(:params) { super().merge!(daemon: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'nsid' do
          let(:params) { super().merge!(nsid: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'identity' do
          let(:params) { super().merge!(identity: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          let(:params) { super().merge!(ip_addresses: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'exports' do
          let(:params) { super().merge!(exports: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'imports' do
          let(:params) { super().merge!(imports: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'ensure' do
          let(:params) { super().merge!(ensure: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'ensure bad option' do
          let(:params) { super().merge!(ensure: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          let(:params) { super().merge!(zones: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'files' do
          let(:params) { super().merge!(files: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'enable_nagios' do
          let(:params) { super().merge!(enable_nagios: '') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
