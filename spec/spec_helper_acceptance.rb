require 'beaker-rspec'
require 'beaker/testmode_switcher/dsl'

module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
master = only_host_with_role(hosts, 'master')
config = {
  'main' => {
    'user' => 'root',
    'group' => 'root',
    'server' => master,
    'static_catalogs' => 'false'
  },
  'master' => {
    'autosign' => 'true'
  }
}
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
master_ip = fact_on(master, 'ipaddress')
hosts.each do |host|
  if host['roles'].include?('master') || ENV['BEAKER_TESTMODE'] == 'apply'
    if host['roles'].include?('master')
      step 'Configure Puppet Master Server'
      host.install_package('puppetserver')
      on(host, 'echo "JAVA_ARGS=\"-Xms1g -Xmx1g -XX:MaxPermSize=128m\"" >> /etc/default/puppetserver')
      config['main']['user'] = 'puppet'
      config['main']['group'] = 'puppet'
    else
      step 'Masterless run'
    end
    install_dev_puppet_module_on(host, source: module_root)
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
    step 'Configure Puppet Agent'
    on(host, "echo '#{master_ip} #{master}' >> /etc/hosts")
  end
  config['main']['certname'] = host
  configure_puppet_on(host, config)
end
on(master, 'service puppetserver start')
RSpec.configure do |c|
  c.formatter = :documentation
  # c.before :suite do
  #   hosts.each do |host|
  #   end
  # end
end
