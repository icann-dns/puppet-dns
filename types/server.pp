type Dns::Server = Struct[{
  address4          => Optional[Tea::Ipv4],
  address6          => Optional[Tea::Ipv6],
  fetch_tsig_name   => Optional[String],
  provide_tsig_name => Optional[String],
}]
