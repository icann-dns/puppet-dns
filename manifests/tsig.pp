# @summary define for configuering tsig keys
# @param algo the tsig algorithem
# @param key_name The Tsig name
# @param data the tsig key
#
define dns::tsig (
  String    $data,
  Dns::Algo $algo     = 'hmac-sha256',
  # TODO: Have this default to $title (currently this is done ion the daemon template
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
