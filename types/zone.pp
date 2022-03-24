type Dns::Zone = Struct[{
  signed                 => Optional[Boolean],
  signer_policy          => Optional[String],
  masters                => Optional[Array[String]],
  provide_xfrs           => Optional[Array[String]],
  tsig_name              => Optional[String],
  zonefile               => Optional[String],
  allow_notify_additions => Optional[Array[String]],
  send_notify_additions  => Optional[Array[String]],
  zonemd_verify          => Optional[Enum['on','off']],
  zonemd_generate        => Optional[Enum['none','zonemd-sha384','zonemd-sha512','remove']],
}]
