[![Build Status](https://travis-ci.org/icann-dns/puppet-dns.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-dns)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/dns.svg?maxAge=2592000)](https://forge.puppet.com/icann/dns)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/dns.svg?maxAge=2592000)](https://forge.puppet.com/icann/dns)

# dns

# WARNING: 0.2.x is *NOT* backwards compatiple with 0.1.x

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with dns](#setup)
    * [What dns affects](#what-dns-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dns](#beginning-with-dns)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Basic Config](#basic-config)
    * [Master Slave Config](#master-slave-config)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Manage the installation and configuration of knot and nsd installations.  Also allows for managing master -> slave relations via exported resources.

## Module Description

This module acts as an interface to icann-nsd and icann-knot to allow the same config yto manage both servers and ease switch between the two daemons.  It can also use exportedconcat resources to manage master slave relationships

## Setup

### What dns affects

* installs and manages icann-knot
* installs and manages icann-nsd
* dynamicly sets processor count based on installed processes
* Optionaly install zonecheck python library and associated cron job.  (if thier is a problem with dns a custom fact is created which can be used by other modules, see icann-quagga)

### Setup Requirements 

* puppetlabs-stdlib 4.12.0
* puppetlabs-concat 1.2.0
* icann-knot 0.2.0
* icann-nsd 0.2.0
* icann-tea 0.2.8
* stankevich-python 1.15.0

### Beginning with dns

install either a dns daemon, which one depends on OS:

```puppet 
class { '::dns': }
```

Force a specific daemon and disable zonecheck

```puppet
class { '::dns':
  daemon => 'knot',
  enable_zonecheck => false,
}
```

and in hiera

```yaml
dns::daemon: knot
dns::enable_zonecheck: false
```

## Usage

### Basic Config

Add config with primary tsig key

```puppet
class {'::dns':
  default_tsig_name: 'test',
  tsigs => {
    'test',=>  {
      'algo' => 'hmac-sha256',
      'data' => 'adsasdasdasd='
    }
  }
}
```

or with hiera

```yaml
nsd::default_tsig_name: test
nsd::tsigs:
  test:
    algo: hmac-sha256
    data: adsasdasdasd=
```

add zone files.  zone files are added with sets of common config.

```puppet
class {'::nsd':
  remotes => {
    master_v4 => { 'address4' => '192.0.2.1' },
    master_v6 => { 'address6' => '2001:DB8::1' },
    slave     => { 'address4' => '192.0.2.2' },
  }
  zones => {
    'example.com' => {
      'masters' => ['master_v4', 'master_v6']
      'provide_xfrs'  => ['slave'],
    },
    'example.net' => {
      'masters' => ['master_v4', 'master_v6']
      'provide_xfrs'  => ['slave'],
    }
    'example.org' => {
      'masters' => ['master_v4', 'master_v6']
      'provide_xfrs'  => ['slave'],
    }
  }
}
```

in hiera

```yaml
nsd::remotes:
  master_v4:
    address4: 192.0.2.1
  master_v6:
    address4: 2001:DB8::1
  slave:
    address4: 192.0.2.2
nsd::zones:
  example.com:
    masters: &id001
    - master_v4
    - master_v6
    provide_xfrs: &id002
    - slave
  example.net:
    masters: *id001
    slave: *id002
  example.org:
    masters: *id001
    slave: *id002
```

create and as112 server

```puppet
class {'::nsd::as112': }
```

#### Master Slave Config

This module makes exports dns::tsig and dns::remote objects from one set of servers and imports them into another set of servers to allow you to configure master slave relations

The parameters `dns::imports` and `dns::exports` are used to create pairs.  if one server has `dns::exports = ['test']` then a master server would import this config by including `dns::imports = ['test']`.  The way that the importing and exporting works in the nsd and knot modules assumes you are running a monolithic install.  Other puppet configuerations will need some effort to get working.

####  Simple master server example

The following is an example where we have one server pull the root zones from xfr.dns.icann.org and then distributes the zones to a second layer of dns servers that use tsig keys, note the TSIG key was created specificly for this example it should not be used in a production environment.  the following examples will use hiera for config

##### Distributions server
Assume the ip address of this server is 192.0.2.1

```puppet
include dns
```

```yaml
dns::imports: ['rootserver']
dns::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
dns::default_masters:
- lax.xfr.dns.icann.org
- iad.xfr.dns.icann.org
dns::zones:
  '.':
    zonefile: root
  'arpa.': {}
  'root-servers.net.': {}
```

##### Edge server
dns::exports: ['rootserver']
dns::tsigs:
  edge_tsig:
    data: 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
dns::remotes:
  distribution_server:
    address4: 192.0.2.1
dns::default_masters:
- distribution_server
dns::zones:
  '.':
    zonefile: root
  'arpa.': {}
  'root-servers.net.': {}

####  Complex master server example

  The following is an example where we have three layers of server top layer -> middle -> edge.  The basics of this is to demonstrate how a server (middle) can both import and export configuration.  This example will also use hiera  with a hierarchy as follows, this allows you to configure the zones in one common locatio9ns and the relations ships in the node specific filess, this allows you to configure the zones in one common locatio9ns and the relations ships in the node specific files

```yaml
:hierarchy:
  - "nodes/%{trusted.certname}"
  - "common"
```
##### Common.yaml

```yaml
dns::zones:
- in-addr.arpa: {}
- in-addr-servers.arpa: {}
- ip6.arpa: {}
- ip6-servers.arpa: {}
- mcast.net: {}
- as112.arpa: {}
- example.com: {}
- example.edu: {}
- example.net: {}
- example.org: {}
- ipv4only.arpa: {}
- 224.in-addr.arpa: {}
- 225.in-addr.arpa: {}
- 226.in-addr.arpa: {}
- 227.in-addr.arpa: {}
- 228.in-addr.arpa: {}
- 229.in-addr.arpa: {}
- 230.in-addr.arpa: {}
- 231.in-addr.arpa: {}
- 232.in-addr.arpa: {}
- 233.in-addr.arpa: {}
- 234.in-addr.arpa: {}
- 235.in-addr.arpa: {}
- 236.in-addr.arpa: {}
- 237.in-addr.arpa: {}
- 238.in-addr.arpa: {}
- 239.in-addr.arpa: {}
```
#####  Top layer server:
Assume the ip address of this server is 192.0.2.1

```yaml
dns::imports: ['top_layer']
dns::daemon: nsd
dns::remotes:
  lax.xfr.dns.icann.org:
    address4: 192.0.32.132
    address6: 2620:0:2d0:202::132
  iad.xfr.dns.icann.org:
    address4: 192.0.47.132
    address6: 2620:0:2830:202::132
dns::default_masters:
- lax.xfr.dns.icann.org
- iad.xfr.dns.icann.org
```

#####  Mid layer server:
Assume the ip address of this server is 192.0.2.2

```yaml
dns::exports: ['top_layer']
dns::imports: ['mid_layer']
dns::default_tsig_name: mid_layer_tsig
dns::tsigs:
  mid_layer_tsig:
    data: qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0=
dns::remotes:
  top_server:
    address4: 192.0.2.1
dns::default_masters:
- top_server
```

##### Edge leyer server
```yaml
dns::exports: ['mid_layer']
dns::default_tsig_name: edge_layer_key
dns::tsigs:
  edge_layer_key:
    L7WLyxJGM5X8tfmzMKdfaQt369JWxAMTmm09ZFgMTc4=
dns::remotes:
  mid_layer_server:
    address4: 192.0.2.2
dns::default_masters:
- mid_layer_server
```

## Reference


- [**Public Classes**](#public-classes)
    - [`dns`](#class-dns)
- [**Private Classes**](#private-classes)
    - [`dns::params`](#class-dnsparams)

### Classes

### Public Classes

#### Class: `dns`
  Guides the basic setup and installation of KNOT on your system
  
##### Parameters (all optional)

* `default_tsig_name` (Optional[String], Default: undef): the default tsig to use when fetching zone data. Knot::Tsig[$default_tsig_name] must exist
* `default_masters` (Array[String], Default: []): Array of Knot::Remote names to use as the default master servers if none are specified in the zone hash
* `default_provide_xfrs` (Array[String], Default: []): Array of Knot::Remote names to use as the provide_xfr servers if none are specified in the zone hash
* `daemon` (/^(nsd|knot)$/, Default: os dependent): which daemon to use
* `nsid` (String, Default: FQDN): string to use for EDNS NSID queires
* `identity` (String, Default: FQDN): string to use for hostname.bind queires
* `ip_addresses` (Array, Default: [@ipaddress]): IP addresses that daemon should listen on
* `imports` (Array, Deafult: []): Array of dns::exports to import
* `exports` (Array, Default: []): Array of dns::imports to export to
* `ensure` (Pattern[/^(present|absent)$/], Default: present): whether to install dns daemon
* `enable_zonecheck` (Boolean, Default: true): Weather to install and manage zonecheck
* `zones` (Hash, Default: {}): A hash of nsd::zone or knot::zone resourves
* `files` (Hash, Default: {}): A hash of nsd::file or knot::file resourves
* `tsigs` (Hash, Default: {}): A hash of nsd::tsig or knot::tsig 
* `enable_nagios` (Boolean, Default: false): export nagios_Service definitions for each zone 

### Private Classes

#### Class `dns::params`

Set os specific parameters

## Limitations

This module has been tested on:

* Ubuntu 12.04, 14.04
* FreeBSD 10

## Development

Pull requests welcome but please also update documentation and tests.
