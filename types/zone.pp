type Dns::Zone = Struct[{
  signed                => Boolean,
  signer_policy         => Optional[String],
  masters               => Optional[Array[String]],
  slaves                => Optional[Array[String]],
  tsig_name_override    => Optional[String],
  allow_notify_override => Optional[Array[String]],
  send_notify_override  => Optional[Array[String]],
  zonefile_override     => Optional[String],
}]
