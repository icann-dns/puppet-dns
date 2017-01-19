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
      #:version => "1.0.14",
      #:syslog_level => "error",
      #:ip_addresses => [],
      #:zones => {},
      #:tsig => {},

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
        facts
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_package('zonecheck').with(
            'ensure'   => '1.0.14',
            'provider' => 'pip'
          )
        end
        it do
          is_expected.to contain_file('/usr/local/etc/zone_check.conf').with_ensure(
            'present'
          ).with_content(
            %r{zones: \{\}},
          ).with_content(
            %r{tsig: \{\}},
          ).with_content(
            %r{ip_addresses: \[\]},
          )
        end
        it do
          is_expected.to contain_cron('/usr/local/bin/zonecheck').with(
            'ensure' => 'present',
            'command' => '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -v',
            'minute' => '*/15'
          )
        end
  
      end
      describe 'Change Defaults' do
        context 'enable' do
          before { params.merge!(enable: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/etc/zone_check.conf'
            ).with_ensure('absent')
          end
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_ensure(
              'absent'
            )
          end
        end
        context 'version' do
          before { params.merge!(version: 'foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_package("zonecheck").with_ensure('foobar') }
        end
        context 'syslog_level critical' do
          before { params.merge!(syslog_level: 'critical') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts '
            )
          end
        end
        context 'syslog_level warn' do
          before { params.merge!(syslog_level: 'warn') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -vv'
            )
          end
        end
        context 'syslog_level info' do
          before { params.merge!(syslog_level: 'info') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -vvv'
            )
          end
        end
        context 'syslog_level debug' do
          before { params.merge!(syslog_level: 'debug') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('/usr/local/bin/zonecheck').with_command(
              '/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts -vvvv'
            )
          end
        end
        context 'ip_addresses' do
          before { params.merge!(ip_addresses: ['192.2.0.1']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/etc/zone_check.conf'
            ).with_content(
              %r{ip_addresses:\n-\s+192.2.0.1}
            )
          end
        end
        context 'zones' do
          before do
            params.merge!(
              zones: { 'example.com' => { 'signed' => true }}
            ) 
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/etc/zone_check.conf'
            ).with_content(
              %r{zones:\s+example.com:\s+signed: true}
            )
          end
        end
        context 'tsig' do
          before do
            params.merge!(
              tsig: { 
                'example.com' => {
                  'data' => 'foobar',
                  'algo' => 'hmac-sha1'
                }
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/etc/zone_check.conf'
            ).with_content(
              %r{tsig:\s+example.com:\s+data: foobar\s+algo: hmac-sha1},
            )
          end
        end
      end
      describe 'check bad type' do
        context 'enable' do
          before { params.merge!(enable: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'version' do
          before { params.merge!(version: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'syslog_level' do
          before { params.merge!(syslog_level: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'syslog_bad string' do
          before { params.merge!(syslog_level: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          before { params.merge!(ip_addresses: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          before { params.merge!(zones: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig' do
          before { params.merge!(tsig: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
