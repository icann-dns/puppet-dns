require 'spec_helper_acceptance'

describe 'nsd class' do
  ipaddress = fact('ipaddress')
  context 'root' do
    it 'should work with no errors' do
      pp = <<-EOS
  class {'::dns': 
    daemon => 'nsd',
    zones => {
      'root' => {
        'masters'  => ['192.0.32.132', '192.0.47.132'],
        'zonefile' => 'root',
        'zones' => ['.'],
      },
      'arpa_and_root_servers' => {
        'masters'  => ['192.0.32.132', '192.0.47.132'],
        'zones' => ['arpa.', 'root-servers.net.'],
      },
    },
  }
      EOS
      apply_manifest(pp ,  :catch_failures => true)
      apply_manifest(pp ,  :catch_failures => true)
      expect(apply_manifest(pp,  :catch_failures => true).exit_code).to eq 0
      #sleep to allow zone transfer (value probably to high)
      sleep(10)
    end
    describe service('nsd') do
      it { is_expected.to be_running }
    end
    describe port(53) do 
      it { is_expected.to be_listening }
    end
    describe command("nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf"), :if => os[:family] == 'ubuntu' do
      its(:stdout) { should match // }
    end
    describe command("nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf"), :if => os[:family] == 'freebsd' do
      its(:stdout) { should match // }
    end
    describe command("dig +short soa . @#{ipaddress}") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /a.root-servers.net. nstld.verisign-grs.com./ }
    end
    describe command("dig +short soa arpa. @#{ipaddress}") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /a.root-servers.net. nstld.verisign-grs.com./ }
    end
    describe command("dig +short soa root-servers.net. @#{ipaddress}") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /a.root-servers.net. nstld.verisign-grs.com./ }
    end
  end
end
