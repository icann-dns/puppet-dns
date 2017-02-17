type Dns::Zone = Struct[{
  signed                 => Boolean,
  signer_policy          => Optional[String],
  masters                => Optional[Array[String]],
  provide_xfrs           => Optional[Array[String]],
  tsig_name              => Optional[String],
  zonefile               => Optional[String],
  allow_notify_additions => Optional[Array[String]],
  send_notify_additions  => Optional[Array[String]],
}]
