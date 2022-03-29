# dns::tsig
#
# === Parameters:
#
# $data::     'tsig_data_value'
# $algo::     'hmac-sha256'
# $key_name:: 'tsig_name'
#
define dns::tsig (
  Dns::Algo $algo     = 'hmac-sha256',
  String    $data     = undef,
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
