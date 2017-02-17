type Dns::Remote = Struct[{
  address4  => Optional[Variant[Tea::Ipv4, Tea::Ipv4_cidr]],
  address6  => Optional[Variant[Tea::Ipv6, Tea::Ipv6_cidr]],
  tsig_name => Optional[String],
  port      => Optional[Tea::Port],
}]
