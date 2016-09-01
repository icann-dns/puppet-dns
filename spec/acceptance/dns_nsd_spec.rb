require 'spec_helper_acceptance'

describe 'nsd class' do
  context 'defaults' do
    it 'should work with no errors' do
      pp = 'class {\'::dns\': daemon => \'nsd\' }'
      apply_manifest(pp ,  :catch_failures => true)
      expect(apply_manifest(pp,  :catch_failures => true).exit_code).to eq 0
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
  end
end
