# dns::remote
#
# === Parameters:
#
# $address4::  '192.168.1.1'
# $address6::  '2000:abcd::ba'
# $tsig::      'tsig_value'
# $tsig_name:: 'tsig_name'
# $port::       53
#
define dns::remote (
  Optional[Stdlib::IP::Address::V4] $address4  = undef,
  Optional[Stdlib::IP::Address::V6] $address6  = undef,
  Optional[String]                  $tsig      = undef,
  Optional[String]                  $tsig_name = undef,
  Stdlib::Port                      $port      = 53,
) {
  @@nsd::remote { $name:
    address4  => $address4,
    address6  => $address6,
    tsig      => $tsig,
    tsig_name => $tsig_name,
    port      => $port,
  }
  @@knot::remote { $name:
    address4  => $address4,
    address6  => $address6,
    tsig      => $tsig,
    tsig_name => $tsig_name,
    port      => $port,
  }
}
