type Dns::Zone = Struct[{
  signed                => Boolean,
  signer_policy         => Optional[String],
  masters               => Optional[Array[String]],
  provide_xfr           => Optional[Array[String]],
  fetch_tsig_name       => Optional[String],
  provide_tsig_name     => Optional[String],
  allow_notify_override => Optional[Array[String]],
  send_notify_override  => Optional[Array[String]],
  zonefile_override     => Optional[String],
}]
