require 'beaker-rspec'

# Install Puppet on all hosts
hosts.each do |host|
  if host['platform'] =~ %r{freebsd}
    # default installs incorect version
    host.install_package('sysutils/puppet4')
    host.install_package('dns/bind-tools')
    # install_puppet_on(host)
  else
    install_puppet_on(
      host,
      version: '4',
      puppet_agent_version: '1.6.1',
      default_action: 'gem_install'
    )
  end
end

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  c.formatter = :documentation
  c.before :suite do
    # Install module to all hosts
    hosts.each do |host|
      install_dev_puppet_module_on(host, source: module_root)
      # Install dependencies
      on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
      on(host, puppet('module', 'install', 'puppetlabs-concat'))
      on(host, puppet('module', 'install', 'stankevich-python'))
      on(host, puppet('module', 'install', 'icann-knot'))
      on(host, puppet('module', 'install', 'icann-nsd'))
      on(host, puppet('module', 'install', 'icann-tea'))
    end
  end
end
