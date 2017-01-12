type Dns::Tsig = Struct[{
  type => Enum[hmac-sha1,hmac-sha224,hmac-sha256,hmac-sha384,hmac-sha512, hmac-md5],
  data => String,
}]
