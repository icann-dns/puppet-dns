require 'beaker-rspec'

# Install Puppet on all hosts
hosts.each do |host|
  host.install_package('git')
  if host['platform'] =~ %r{freebsd}
    # default installs incorect version
    host.install_package('sysutils/puppet4')
    host.install_package('dns/bind-tools')
    # install_puppet_on(host)
  else
    host.install_package('vim')
    host.install_package('dnsutils')
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
  git_repos = [
    {
      mod: 'nsd',
      branch: 'refactor_zone',
      repo: 'https://github.com/icann-dns/puppet-nsd'
    },
    {
      mod: 'knot',
      branch: 'refactor_zone',
      repo: 'https://github.com/icann-dns/puppet-knot'
    }
  ]
  c.formatter = :documentation
  c.before :suite do
    # Install module to all hosts
    hosts.each do |host|
      install_dev_puppet_module_on(host, source: module_root)
      if (host['roles'] & %w(master masterless)).any?
        step 'Configure master or masterless'
        on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
        on(host, puppet('module', 'install', 'puppetlabs-concat'))
        on(host, puppet('module', 'install', 'stankevich-python'))
        on(host, puppet('module', 'install', 'icann-tea'))
        # on(host, puppet('module', 'install', 'icann-knot'))
        # on(host, puppet('module', 'install', 'icann-nsd'))
        git_repos.each do |g|
          step "Installing puppet module \'#{g[:repo]}\' from git on Master to #{default['distmoduledir']}"
          on(host, "git clone -b #{g[:branch]} --single-branch #{g[:repo]} #{default['distmoduledir']}/#{g[:mod]}")
        end
      else
          step 'configure Agent'
      end
    end
  end
end
