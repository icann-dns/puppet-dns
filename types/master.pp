type Dns::Server = Struct[{
  address4   => Optional[Tea::Ipv4],
  address6   => Optional[Tea::Ipv6],
  tsig_name => Optional[String],
}]
