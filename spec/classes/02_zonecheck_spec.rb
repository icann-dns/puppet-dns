# frozen_string_literal: true

require 'spec_helper'

describe 'dns::zonecheck' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'zonecheck.example.com' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #:enable => true,
      #:syslog_level => "error",
    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(
          environment: 'production',
          ipaddress: '192.0.2.2',
          networking: { 'ip' => '192.0.2.1', 'ip6' => '2001:DB8::1' },
        )
      end
      let(:pre_condition) do
        'class {\'::dns\':
          default_tsig_name => \'foobar\',
          default_masters => [ \'master\' ],
          default_provide_xfrs => [\'slave\'],
          tsigs   => {
            \'foobar\' => {
              data => \'asdasd\'
            }
          },
          zones => {
            \'.\' => {},
            \'arpa.\' => {},
            \'root-servers.net.\' => {}
          },
          remotes => {
            \'extra_allow_notify\' => {
              \'address4\' => \'192.0.2.4\',
              \'address6\' => \'2001:DB8::4\'
            },
            \'extra_notify\' => {
              \'address4\' => \'192.0.2.3\',
              \'address6\' => \'2001:DB8::3\'
            },
            \'master\' => {
              \'address4\' => \'192.0.2.1\',
              \'address6\' => \'2001:DB8::1\'
            },
            \'slave\' => {
              \'address4\' => \'192.0.2.2\',
              \'address6\' => \'2001:DB8::2\'
            }
          }
        }'
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('dns::zonecheck') }
        it do
          is_expected.to contain_python__pip('zonecheck').with(
            'ensure' => 'latest',
          )
        end
        it do
          is_expected.to contain_file('/usr/local/etc/zone_check.conf').with_ensure(
            'present',
          ).with_content(
            %r{
              zones:
              \s+default_zoneset:
                \s+masters:
                \s+-\s192.0.2.1
                \s+-\s2001:DB8::1
                \s+zones:
                \s+-\s"."
                \s+-\sarpa.
                \s+-\sroot-servers.net.
              \s+tsig:
                \s+algo:\shmac-sha256
                \s+name:\sfoobar
                \s+data:\sasdasd
              \s+ip_addresses:
                \s+-\s192.0.2.2
            }x,
          )
        end
        it do
          is_expected.to contain_cron('/usr/local/bin/zonecheck').with(
            'ensure' => 'present',
            'command' => '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -v',
            'minute' => '*/15',
          )
        end
      end
      describe 'Change Defaults' do
        context 'enable' do
          before(:each) { params.merge!(enable: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/etc/zone_check.conf',
            ).with_ensure('absent')
          end
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_ensure(
              'absent',
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/puppetlabs/facter/facts.d/zone_status.txt',
            ).with_content('zone_status_errors=false')
          end
        end
        context 'syslog_level critical' do
          before(:each) { params.merge!(syslog_level: 'critical') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts ',
            )
          end
        end
        context 'syslog_level warn' do
          before(:each) { params.merge!(syslog_level: 'warn') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -vv',
            )
          end
        end
        context 'syslog_level info' do
          before(:each) { params.merge!(syslog_level: 'info') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -vvv',
            )
          end
        end
        context 'syslog_level debug' do
          before(:each) { params.merge!(syslog_level: 'debug') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -vvvv',
            )
          end
        end
      end
      describe 'check bad type' do
        context 'enable' do
          before(:each) { params.merge!(enable: 'foobar') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'syslog_level' do
          before(:each) { params.merge!(syslog_level: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'syslog_bad string' do
          before(:each) { params.merge!(syslog_level: 'foobar') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
