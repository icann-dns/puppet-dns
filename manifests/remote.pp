# dns::remote
#
define dns::remote (
  Optional[Variant[Tea::Ipv4, Tea::Ipv4_cidr]] $address4  = undef,
  Optional[Variant[Tea::Ipv6, Tea::Ipv6_cidr]] $address6  = undef,
  Optional[String]                             $tsig       = undef,
  Optional[String]                             $tsig_name = undef,
  Tea::Port                                    $port      = 53,
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
