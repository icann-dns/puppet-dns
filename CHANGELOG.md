### 2024-01-09 1.0.01
* Fix typo introduced in 6.0.0
* drop support for FreeBSD
* drop support for ubuntu < 18.04
* Use puppet-strings format for docs and generate REFERENCES.md
* drop params.pp file

### 2024-01-08 0.7.0
* Update module to allow users to pass required services

### 2022-03-24 0.6.1
* setup zonemd support including zonemd-generate and zonemd-verify for KNOT

### 2020-01-02 0.5.3
* setup the zone_check.conf file always for monitoring purposes

### 2018-11-16 0.5.1
* revert back to using provider => pip

### 2018-09-28 0.5.0
* use stdlib types instead of tea types where possible
* use python::pip to install packages
* convert PDK
* update spec\_helper\_acceptance to work with beaker v4

### 2018-07-03 0.4.2
* update spec tests

### 2018-07-02 0.4.1
* add support for monitoring class

### 2017-09-22 0.4.0
* add opendnssec support

### 2017-09-22 0.3.0
* changed the way we manage exported resources 
* update so that we support icann-knot 0.3.x

### 2017-09-07 0.2.11
* iadd flag to reject privat ip addresses.  this allows us to remove link-local ipv6 addresses when using facts['address6'] for the default\_ipv6 address

### 2017-09-07 0.2.10
* bump zonecheck

### 2017-08-30 0.2.9
* change importexport tags to ovoid conflicts

### 2017-08-17 0.2.8
* Add sleeps in spec test
* also import dns resources for transition

### 2017-08-16 0.2.7
* Add backwards compatibilitry to use for mirgartion
* updated spec test

### 2017-04-10 0.2.6
* FIX: ensure enable\_nagios works with default\_masters

### 2017-04-10 0.2.5
* Dont pin exports to environments

### 2017-04-10 0.2.4
* Add checks for none existent masters in erb template

### 2017-04-10 0.2.3
* Fix spec tests

### 2017-04-10 0.2.2
* change zonecheck format to deal with zones that dont use the default masters

### 2017-04-10 0.2.1
* update dependencies

### 2017-04-06 0.2.0
* Complete rewrite of the zones hash.
* depricated the old $tsig hash now all hashs have to be defined in $tsisg and then refrenced by name in the remotes
* added new nsd::remotes define.  allows you to define data about remote servers and then refrence them by name where ever a zone paramter would require a server e.g. masters, provide_xfrs, notifis etc
* added default_tsig_name.  this specifies which nsd::tsig should be used by default
* added default_masters.  this specifies an array of nsd::remote to use by default
* added default_provide_xfrs.  this specifies an array of nsd::remote to use by default

### 2016-11-14 0.1.11
* add ability to change logging level of zone check

### 2016-11-14 0.1.10
* bump zonecheck version

### 2016-11-14 0.1.9
* Updated enable_zonecheck paramters so that it removes the cron job and configuration file if set to false
* enable parameter to change zonecheck version
* switch to using icann-tea for generic types

### 2016-10-03 0.1.8
* bump zonecheck version

### 2016-10-03 0.1.7
* bump zonecheck version

### 2016-09-05 0.1.6
* bump zonecheck version

### 2016-09-05 0.1.5
* Remove nagios checks for slaves

### 2016-09-05 0.1.4
* bump zonecheck version

### 2016-09-05 0.1.3
* Fix bug in nagios checks where we ehere creating erronous slave/master checks

### 2016-09-05 0.1.2
* Add nagios_service support

### 2016-09-05 0.1.1
* Improve IPv6 regex

### 2016-07-07 0.1.0
* Initial release

