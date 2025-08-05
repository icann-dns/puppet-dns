# frozen_string_literal: true

require 'spec_helper'

describe 'dns::as112' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'with nsd' do
        let(:pre_condition) { "class dns {  $daemon = 'nsd' }" }

        it { is_expected.to compile.with_all_deps }
      end

      describe 'with knot' do
        let(:pre_condition) { "class dns {  $daemon = 'knot' }" }

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
