[![Build Status](https://travis-ci.org/icann-dns/puppet-dns.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-dns)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/dns.svg?maxAge=2592000)](https://forge.puppet.com/icann/dns)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/dns.svg?maxAge=2592000)](https://forge.puppet.com/icann/dns)

# dns

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
* Optionaly install zonecheck python library and associated cron job.  if the is a problem mwith dns a custom fact is created which can be used by other modules (see icann-quagga)

### Setup Requirements 

* puppetlabs-stdlib 4.12.0 (may work with earlier versions)
* puppetlabs-concat 1.2.0
* icann-knot 0.1.3
* icann-nsd 0.1.3
* stankevich-python 1.15.0

### Beginning with dns

install either icann-nsd or -cann-knot depending on the operating system:

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
  tsig => {
    'name' => 'test',
    'algo' => 'hmac-sha256',
    'data' => 'adsasdasdasd='
  }
}
```

or with hiera

```yaml
dns::tsig:
  name: test
  algo: hmac-sha256
  data: adsasdasdasd=
```

add zone files.  zone files are added with sets of common config.

```puppet
class {'::dns': 
  zones => {
    'master1_zones' => {
      'allow_notify' => ['192.0.2.1'],
      'masters'      => ['192.0.2.1'],
      'provide_xfr'  => ['127.0.0.1'],
      'zones'        => ['example.com', 'example.net']
    },
    'master2_zones'  => {
      'allow_notify' => ['192.0.2.2'],
      'masters'      => ['192.0.2.2'],
      'provide_xfr'  => ['127.0.0.2'],
      'zones'        => ['example.org']
    }
  }
}
```

in hiera

```yaml
dns::zones:
  master1_zones:
    allow_notify:
    - 192.0.2.1
    masters:
    - 192.0.2.1
    provide_xfr:
    - 192.0.2.1
    zones:
    - example.com
    - example.net
  master2_zones:
    allow_notify:
    - 192.0.2.2
    masters:
    - 192.0.2.2
    provide_xfr:
    - 192.0.2.2
    zones:
    - example.org
```

creat and as112 server also uses the dns::file resource

```puppet
  class {'::dns': 
    zones =>  {
      'rfc1918' => { 
        'zonefile' => 'db.dd-empty',
        'zones' => [
          '10.in-addr.arpa',
          '16.172.in-addr.arpa',
          '17.172.in-addr.arpa',
          '18.172.in-addr.arpa',
          '19.172.in-addr.arpa',
          '20.172.in-addr.arpa',
          '21.172.in-addr.arpa',
          '22.172.in-addr.arpa',
          '23.172.in-addr.arpa',
          '24.172.in-addr.arpa',
          '25.172.in-addr.arpa',
          '26.172.in-addr.arpa',
          '27.172.in-addr.arpa',
          '28.172.in-addr.arpa',
          '29.172.in-addr.arpa',
          '30.172.in-addr.arpa',
          '31.172.in-addr.arpa',
          '168.192.in-addr.arpa',
          '254.169.in-addr.arpa'
        ]
      },
      'empty.as112.arpa' => {
        'zonefile' => 'db.dr-empty',
        'zones'    => ['empty.as112.arpa'],
      },
      'hostname.as112.net' => {
        'zonefile' => 'hostname.as112.net.zone',
        'zones'    =>  ['hostname.as112.net'],
      }
      'hostname.as112.arpa' => {
        'zonefile' => 'hostname.as112.arpa.zone',
        'zones'    => ['hostname.as112.arpa'],
      },
    },
    files => {
      'db.dd-empty' => {
        source  => 'puppet:///modules/dns/etc/dns/db.dd-empty',
      },
      'db.dr-empty' => {
        source  => 'puppet:///modules/dns/etc/dns/db.dr-empty',
      }
      'hostname.as112.net.zone' => {
        content_template => 'dns/etc/dns/hostname.as112.net.zone.erb',
      }
      'hostname.as112.arpa.zone' => {
        content_template => 'dns/etc/dns/hostname.as112.arpa.zone.erb',
      }
    }
  }
```

```yaml
dns::files:
  db.dd-empty:
    source: 'puppet:///modules/dns/etc/dns/db.dd-empty'
  db.dr-empty:
    source: 'puppet:///modules/dns/etc/dns/db.dr-empty'
  hostname.as112.net.zone:
    content_template: 'dns/etc/dns/hostname.as112.net.zone.erb'
  hostname.as112.arpa.zone:
    content_template: 'dns/etc/dns/hostname.as112.arpa.zone.erb'
dns::zones:
  rfc1918:
    zonefile: db.dd-empty
    zones:
    - 10.in-addr.arpa
    - 16.172.in-addr.arpa
    - 17.172.in-addr.arpa
    - 18.172.in-addr.arpa
    - 19.172.in-addr.arpa
    - 20.172.in-addr.arpa
    - 21.172.in-addr.arpa
    - 22.172.in-addr.arpa
    - 23.172.in-addr.arpa
    - 24.172.in-addr.arpa
    - 25.172.in-addr.arpa
    - 26.172.in-addr.arpa
    - 27.172.in-addr.arpa
    - 28.172.in-addr.arpa
    - 29.172.in-addr.arpa
    - 30.172.in-addr.arpa
    - 31.172.in-addr.arpa
    - 168.192.in-addr.arpa
    - 254.169.in-addr.arpa
  'empty.as112.arpa':
    zonefile: db.dr-empty
    zones:
    - empty.as112.arpa
  'hostname.as112.net':
    zonefile: hostname.as112.net.zone
    zones:
    - hostname.as112.net
  'hostname.as112.arpa':
    zonefile: hostname.as112.arpa.zone
    zones:
    - hostname.as112.arpa
```

#### Master Slave Config

This module makes use of exported concat fragments so that we can configure slave IP address and TSIG keys on the master server.  This is done by managing the following files in the custom facts directory on the master server.
  * /etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml
  * /etc/puppetlabs/facter/facts.d/dns_slave_tsigs.yaml.
As we are relying on custom facts this means that there will be a delay as to when the slave server is configurered on the master server the flow is as follows.  In a future release it is intended to remove the reliance on the custom facts dir (pull requests welcome)
  1) Slave server runs puppet and exports slave configueration
  2) Master server runs puppet and updates custom facts file
  3) master server runs and now sees the new servers configuered by the custom facts

The parameter `dns::instance` is used to create pairs.  All slaves in the same instance will be configured on all masters with the same instance.

puppet policy
```puppet
#Master server ip address = 192.0.2.2
#Slave server ip address = 192.0.2.3
include dns
```

Slave hiera config
```yaml
dns::instance: example.com
dns::tsig:
    algo: hmac-sha256
    data: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
    name: slave.example.com
dns::zones:
  example:
    allow_notify:
    - 192.0.2.2
    masters:
    - 192.0.2.2
    zones:
    - example.com
    - example.net
```

Master hiera config
```yaml
dns::master: true
dns::instance: example.com
dns::tsig:
    algo: hmac-sha256
    data: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=
    name: master.example.com
dns::zones:
  example.com:
    zones:
    - example.com
    - example.net
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

* `daemon` (/^(nsd|knot)$/, Default: os dependent): which daemon to use
* `slaves_target` (Path, Default: /etc/puppetlabs/facter/facts.d/dns_slave_addresses.yaml) patch on master to store facts used for master/slave relationship
* `nsid` (String, Default: FQDN): string to use for EDNS NSID queires
* `identity` (String, Default: FQDN): string to use for hostname.bind queires
* `ip_addresses` (Array, Default: [@ipaddress]): IP addresses that daemon should listen on
* `master` (Boolean, Deafult: true): wheather the system is a master or a slave
* `instance` (String, Default: 'default'): used for master/slave relationships
* `ensure` (Pattern[/^(present|absent)$/], Default: present): whether to install dns daemon
* `enable_zonecheck` (Boolean, Default: true): Weather to install and manage zonecheck
* `zones` (Hash, Default: {}): A hash of nsd::zone or knot::zone resourves
* `files` (Hash, Default: {}): A hash of nsd::file or knot::file resourves
* `tsig` (Hash, Default: {}): A hash of nsd::tsig or knot::tsig 


### Private Classes

#### Class `dns::params`

Set os specific parameters

## Limitations

This module has been tested on:

* Ubuntu 12.04, 14.04
* FreeBSD 10

## Development

Pull requests welcome but please also update documentation and tests.
