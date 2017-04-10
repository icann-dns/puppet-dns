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

