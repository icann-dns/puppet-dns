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
  let(:params) do
    {
      # :daemon => "$::dns::params::daemon",
      # :slaves_target => "$::dns::params::slaves_target",
      # :tsigs_target => "$::dns::params::tsigs_target",
      # :nsid => "$::dns::params::nsid",
      # :identity => "$::dns::params::identity",
      # :ip_addresses => [],
      # :exports => [],
      # :imports => [],
      # :ensure => "present",
      # :zones => {},
      # :files => {},
      # :tsig => {},
      # :enable_nagios => false,
    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(
          environment: 'production',
          ipaddress: '192.0.2.2',
          networking: { 'ip' => '192.0.2.1', 'ip6' => '2001:DB8::1' }
        )
      end

      case facts[:operatingsystem]
      when 'Ubuntu'
        case facts['lsbdistcodename']
        when 'precise'
          let(:nsd_enable) { true }
          let(:knot_enable) { false }
          let(:dns_control) { '/usr/sbin/nsd-control' }
        else
          let(:nsd_enable) { false }
          let(:knot_enable) { true }
          let(:dns_control) { '/usr/sbin/knotc' }
        end
      else
        let(:nsd_enable) { true }
        let(:knot_enable) { false }
        let(:dns_control) { '/usr/sbin/nsd-control' }
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('dns') }
        it { is_expected.to contain_class('dns::params') }
        # it { is_expected.to contain_class('dns::zonecheck') }
        it do
          is_expected.to contain_file('/usr/local/bin/dns-control').with(
            'ensure' => 'link',
            'target' => dns_control
          )
        end
        it do
          is_expected.to contain_class('nsd').with(
            enable: nsd_enable,
            ip_addresses: ['192.0.2.2'],
            server_count: 1,
            nsid: 'dns.example.com',
            identity: 'dns.example.com',
            files: {},
            zones: {},
            tsigs: {},
            remotes: {}
          )
        end
        it do
          is_expected.to contain_class('knot').with(
            enable: knot_enable,
            ip_addresses: ['192.0.2.2'],
            server_count: 1,
            nsid: 'dns.example.com',
            identity: 'dns.example.com',
            files: {},
            zones: {},
            tsigs: {},
            remotes: {}
          )
        end
      end
      describe 'Change Defaults' do
        context 'nsid' do
          before { params.merge!(nsid: 'foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_class('knot').with_nsid('foobar') }
          it { is_expected.to contain_class('nsd').with_nsid('foobar') }
        end
        context 'identity' do
          before { params.merge!(identity: 'foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_class('knot').with_identity('foobar') }
          it { is_expected.to contain_class('nsd').with_identity('foobar') }
        end
        context 'ip_addresses' do
          before do
            params.merge!(ip_addresses: ['192.0.2.2', '2001:DB8::1'])
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_class('nsd').with_ip_addresses(
              ['192.0.2.2', '2001:DB8::1']
            )
          end
          it do
            is_expected.to contain_class('knot').with_ip_addresses(
              ['192.0.2.2', '2001:DB8::1']
            )
          end
        end
        context 'exports' do
          before { params.merge!(exports: ['foobar']) }
          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nsd__remote(
              'dns__export_foobar_dns.example.com'
            ).with(
              address4: '192.0.2.1',
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53
            )
          end
          it do
            expect(exported_resources).to contain_knot__remote(
              'dns__export_foobar_dns.example.com'
            ).with(
              address4: '192.0.2.1',
              address6: '2001:DB8::1',
              tsig_name: 'NOKEY',
              port: 53
            )
          end
        end
        context 'ensure' do
          before { params.merge!(ensure: 'absent') }
          it { is_expected.to compile }
          it { is_expected.not_to contain_class('knot') }
          it { is_expected.not_to contain_class('nsd') }
        end
        context 'zones' do
          before do
            params.merge!(
              zones: {
                'example.com' => {
                  'signed' => true,
                  'masters' => ['master.example.com'],
                  'provide_xfrs' => ['slave.example.com']
                }
              },
              remotes: {
                'master.example.com' => {
                  'address4' => '192.0.2.1'
                },
                'slave.example.com' => {
                  'address4' => '192.0.2.2'
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'files' do
          before do
            params.merge!(
              files: { 'test' => { 'source' => 'puppet:///modules/dns/source' } }
            )
          end
          it { is_expected.to compile }
        end
        context 'tsigs' do
          before { params.merge!(tsigs: { 'test' => { 'data' => 'aaaa' } }) }
          it { is_expected.to compile }
          it { is_expected.to contain_nsd__tsig('test') }
          it { is_expected.to contain_knot__tsig('test') }
        end
        context 'enable_nagios only v4' do
          before do
            params.merge!(
              enable_nagios: true,
              zones: {
                'example.com' => {
                  'signed'  => true,
                  'masters' => ['master.example.com'],
                  'provide_xfrs' => ['slave.example.com']
                }
              },
              remotes: {
                'master.example.com' => {
                  'address4' => '192.0.2.1'
                },
                'slave.example.com' => {
                  'address4' => '192.0.2.2'
                }
              }
            )
          end
          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nagios_service(
              'dns.example.com_DNS_ZONE_MASTERS_example.com'
            ).with(
              'use' => 'generic-service',
              'host_name' => 'dns.example.com',
              'service_description' => 'DNS_ZONE_MASTERS_example.com',
              'check_command' => 'check_nrpe_args!check_dns!example.com!192.0.2.1!192.0.2.2'
            )
          end
        end
        context 'enable_nagios only v6' do
          before do
            params.merge!(
              enable_nagios: true,
              zones: {
                'example.com' => {
                  'signed'  => true,
                  'masters' => ['master.example.com'],
                  'provide_xfrs' => ['slave.example.com']
                }
              },
              remotes: {
                'master.example.com' => {
                  'address6' => '2001:DB8::1'
                },
                'slave.example.com' => {
                  'address4' => '192.0.2.2'
                }
              }
            )
          end
          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nagios_service(
              'dns.example.com_DNS_ZONE_MASTERS_example.com'
            ).with(
              'use' => 'generic-service',
              'host_name' => 'dns.example.com',
              'service_description' => 'DNS_ZONE_MASTERS_example.com',
              'check_command' => 'check_nrpe_args!check_dns!example.com!2001:DB8::1!192.0.2.2'
            )
          end
        end
        context 'enable_nagios only v4 and v6' do
          before do
            params.merge!(
              enable_nagios: true,
              zones: {
                'example.com' => {
                  'signed'  => true,
                  'masters' => ['master.example.com'],
                  'provide_xfrs' => ['slave.example.com']
                }
              },
              remotes: {
                'master.example.com' => {
                  'address4' => '192.0.2.1',
                  'address6' => '2001:DB8::1'
                },
                'slave.example.com' => {
                  'address4' => '192.0.2.2'
                }
              }
            )
          end
          it { is_expected.to compile }
          it do
            expect(exported_resources).to contain_nagios_service(
              'dns.example.com_DNS_ZONE_MASTERS_example.com'
            ).with(
              'use' => 'generic-service',
              'host_name' => 'dns.example.com',
              'service_description' => 'DNS_ZONE_MASTERS_example.com',
              'check_command' => 'check_nrpe_args!check_dns!example.com!192.0.2.1 2001:DB8::1!192.0.2.2'
            )
          end
        end
      end
      describe 'check bad type' do
        context 'daemon' do
          before { params.merge!(daemon: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'daemon bad option' do
          before { params.merge!(daemon: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsid' do
          before { params.merge!(nsid: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'identity' do
          before { params.merge!(identity: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          before { params.merge!(ip_addresses: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'exports' do
          before { params.merge!(exports: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'imports' do
          before { params.merge!(imports: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ensure' do
          before { params.merge!(ensure: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ensure bad option' do
          before { params.merge!(ensure: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          before { params.merge!(zones: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'files' do
          before { params.merge!(files: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_nagios' do
          before { params.merge!(enable_nagios: '') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
