# @summary define for configuering remotes
# @param address4 The IPv4 address of the remote
# @param address6 The IPv4 address of the remote
# @param tsig The name tsig key
# @param tsig_name The name of the tsig key
# @param port The port to contact the remote
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
