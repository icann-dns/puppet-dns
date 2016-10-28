require 'spec_helper'
require 'shared_contexts'

describe 'dns' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera
  let(:node) { 'dns.example.com' }

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
      #:daemon => "$::dns::params::daemon",
      #:slaves_target => "$::dns::params::slaves_target",
      #:tsigs_target => "$::dns::params::tsigs_target",
      #:nsid => "$::dns::params::nsid",
      #:identity => "$::dns::params::identity",
      #:ip_addresses => [],
      #:master => false,
      :instance => 'test',
      #:ensure => "present",
      #:enable_zonecheck => true,
      #:zones => {},
      #:files => {},
      #:tsig => {},
      #:enable_nagios => false,

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          "dns_slave_tsigs"  => {},
          "dns_slave_addresses"  => {},
          "ipaddress" => '192.0.2.2'
        })
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
        it { is_expected.to contain_class('dns::params') }

        
        it do
          is_expected.to contain_package("zonecheck")
        .with({
          "ensure" => "1.0.10",
          "provider" => "pip",
          })
        end
  
        
        it do
         is_expected.to contain_file("/usr/local/etc/zone_check.conf")
        .with({
          "ensure" => "present",
          }).with_content(
            /192.0.2.2/
        )
        end
  
        
        it do
          is_expected.to contain_cron("/usr/local/bin/zonecheck")
        .with({
          "ensure" => "present",
          "command" => "/usr/bin/flock -n /var/lock/zonecheck.lock /usr/local/bin/zonecheck --puppet-facts",
          "minute" => "*/15",
          })
        end
  
        
        it do
          is_expected.to contain_file("/usr/local/bin/dns-control")
        .with({
          "ensure" => "link",
          "target" => dns_control,
          })
        end
  
        it do
          expect(exported_resources).to contain_concat__fragment("dns_slave_tsig_yaml_foo.example.com")
        .with({
          "target" => "/etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml",
          "tag" => "dns::test_slave_tsigs",
          "order" => "10",
          }).with_content(
            /# foo.example.com/
        ).with_content(
          /algo:\s+$/
        ).with_content(
          /data:\s+''$/)
        end
  
        
        it do
         expect(exported_resources).to contain_concat__fragment("dns_slave_addresses_yaml_foo.example.com")
        .with({
          "target" => "/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml",
          "tag" => "dns::test_slave_interface_yaml",
          "content" => "# foo.example.com\n",
          "order" => "10",
          })
        end
  
        
        it do
          is_expected.to contain_class("nsd")
              .with({
          "enable" => nsd_enable,
          "ip_addresses" => ['192.0.2.2'],
          "tsigs" => {},
          "slave_addresses" => {},
          "zones" => {},
          "tsig" => {},
          "server_count" => 1,
          "files" => {},
          "nsid" => "foo.example.com",
          "identity" => "foo.example.com",
          })
        end
  
        
       it do
          is_expected.to contain_class("knot")
        .with({
          "enable" => knot_enable,
          "ip_addresses" => ['192.0.2.2'],
          "tsigs" => {},
          "slave_addresses" => {},
          "zones" => {},
          "tsig" => {},
          "server_count" => 1,
          "files" => {},
          "nsid" => "foo.example.com",
          "identity" => "foo.example.com",
          })
        end
  
      end
      describe 'Change Defaults' do
        context 'slaves_target' do
          before { params.merge!( master: true, slaves_target: '/tmp' ) }
          it { is_expected.to compile }
          # Add Check to validate change was successful

          it { is_expected.to contain_concat("/tmp") }
          it {
            is_expected.to contain_concat__fragment("dns_slave_addresses_yaml_foo.example.com")
            .with({
              "target" => "/tmp",
              "content" => "dns_slave_addresses:\n",
              "order" => "01",
            })
          }
        end
        context 'tsigs_target' do
          before { params.merge!( master: true, tsigs_target: '/tmp' ) }
          it { is_expected.to compile }
          it { is_expected.to contain_concat("/tmp") }
          it {
            is_expected.to contain_concat__fragment("dns_slave_tsigs_yaml_foo.example.com")
              .with({
              "target" => "/tmp",
              "content" => "dns_slave_tsigs:\n",
              "order" => "01",
              }) 
          }
        end
        context 'nsid' do
          before { params.merge!( nsid: 'foobar' ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class("knot").with( "nsid" => "foobar") }
          it { is_expected.to contain_class("nsd").with( "nsid" => "foobar") }
        end
        context 'identity' do
          before { params.merge!( identity: 'foobar' ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class("knot").with("identity" => "foobar") }
          it { is_expected.to contain_class("nsd").with("identity" => "foobar") }
        end
        context 'ip_addresses' do
          before { params.merge!( ip_addresses: [
                                 '192.0.2.2',
                                  '2001:DB8::1',] ) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file("/usr/local/etc/zone_check.conf")
              .with_content(
                /192.0.2.2/
              ).with_content(
              /2001:DB8::1/
            )
          end
        end
        context 'master' do
          before { params.merge!( master: true ) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat("/etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml")
          end
          it do
          is_expected.to contain_concat__fragment("dns_slave_tsigs_yaml_foo.example.com")
          .with({
            "target" => "/etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml",
            "content" => "dns_slave_tsigs:\n",
            "order" => "01",
            })
          end
          it do
            is_expected.to contain_concat("/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml")
          end
        it do
            is_expected.to contain_concat__fragment("dns_slave_addresses_yaml_foo.example.com")
          .with({
            "target" => "/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml",
            "content" => "dns_slave_addresses:\n",
            "order" => "01",
            })
          end
        end
        context 'instance' do
          before { params.merge!( instance: 'foobar' ) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
          expect(exported_resources).to contain_concat__fragment("dns_slave_addresses_yaml_foo.example.com")
          .with({
            "target" => "/etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml",
            "tag" => "dns::foobar_slave_interface_yaml",
            "content" => "# foo.example.com\n",
            "order" => "10",
            })
          end
        end
        context 'ensure' do
          before { params.merge!( ensure: 'absent' ) }
          it { is_expected.to compile }
          it { is_expected.to_not contain_class("knot") }
          it { is_expected.to_not contain_class("nsd") }
        end
        context 'enable_zonecheck' do
          before { params.merge!( enable_zonecheck: false ) }
          it { is_expected.to compile }
          it { is_expected.to_not contain_package("zonecheck") }
          it { is_expected.to_not contain_file("/usr/local/etc/zone_check.conf") }
          it { is_expected.to_not contain_cron("/usr/local/bin/zonecheck") }
        end
        context 'zones' do
          before { 
            params.merge!( 
              zones: { 
                'example.com' => {
                  'masters'          => ['192.0.2.1'],
                  'notify_addresses' => ['192.0.2.1'],
                  'allow_notify'     => ['192.0.2.1'],
                  'provide_xfr'      => ['192.0.2.1'],
                  'zones'            => ['example.com'],
              }
          } ) }
          it { is_expected.to compile }
        end
        context 'files' do
          before { 
            params.merge!(files: {'test' => { 'source' => 'puppet:///source' }})}
          it { is_expected.to compile }
        end
        context 'tsig' do
          before { params.merge!( tsig: { 'name' => 'test', 'data' => 'aaaa' })}
          it { is_expected.to compile }
        end
        context 'enable_nagios' do
          before { 
            params.merge!( 
              enable_nagios: true,
              zones: { 
                'example.com' => {
                  'masters'          => ['192.0.2.1'],
                  'notify_addresses' => ['192.0.2.1'],
                  'allow_notify'     => ['192.0.2.1'],
                  'provide_xfr'      => ['192.0.2.1'],
                  'zones'            => ['example.com'],
              }
          } ) }
          it { is_expected.to compile }
          it {
            expect(exported_resources).to contain_nagios_service(
              "foo.example.com_DNS_ZONE_MASTERS_example.com")
              .with({
              "use" => "generic-service",
              "host_name" => "foo.example.com",
              "service_description" => "DNS_ZONE_MASTERS_example.com",
              "check_command" => "check_nrpe_args!check_dns!example.com!192.0.2.1!192.0.2.2"
            })
          }
        end
      end
      describe 'check bad type' do
        context 'daemon' do
          before { params.merge!( daemon: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'daemon bad option' do
          before { params.merge!( daemon: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'slaves_target' do
          before { params.merge!( slaves_target: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsigs_target' do
          before { params.merge!( tsigs_target: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsid' do
          before { params.merge!( nsid: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'identity' do
          before { params.merge!( identity: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          before { params.merge!( ip_addresses: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'master' do
          before { params.merge!( master: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'instance' do
          before { params.merge!( instance: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ensure' do
          before { params.merge!( ensure: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ensure bad option' do
          before { params.merge!( ensure: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_zonecheck' do
          before { params.merge!( enable_zonecheck: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          before { params.merge!( zones: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'files' do
          before { params.merge!( files: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig' do
          before { params.merge!( tsig: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_nagios' do
          before { params.merge!( tsig: '' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
