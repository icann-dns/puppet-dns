# dns::tsig
#
define dns::tsig (
  String    $data,
  Dns::Algo $algo     = 'hmac-sha256',
  String    $key_name = undef,
) {
  @@nsd::tsig { $name:
    algo     => $algo,
    data     => $data,
    key_name => $key_name,
  }
  @@knot::tsig { $name:
    algo     => $algo,
    data     => $data,
    key_name => $key_name,
  }
}
