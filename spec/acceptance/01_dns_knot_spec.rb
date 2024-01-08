# frozen_string_literal: true

require 'spec_helper_acceptance'

if ENV['BEAKER_TESTMODE'] == 'apply'
  describe 'knot class' do
    context 'defaults' do
      it 'is_expected.to work with no errors' do
        pp = 'class {\'::dns\': daemon => \'knot\' }'
        execute_manifest(pp, catch_failures: true)
        expect(execute_manifest(pp, catch_failures: true).exit_code).to eq 0
      end
      describe service('knot') do
        it { is_expected.to be_running }
      end
      describe port(53) do
        it { is_expected.to be_listening }
      end
      describe command('knotc -c /etc/knot/knot.conf checkconf || cat /etc/knot/knot.conf') do
        its(:stdout) { is_expected.to match %r{} }
      end
    end
  end
end
