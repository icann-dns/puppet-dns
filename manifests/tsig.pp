# dns::tsig
#
define dns::tsig_wrap (
  String    $data,
  Dns::Algo $algo = 'hmac-sha256',
) {
  nsd::tsig { $name:
    algo => $algo,
    data => $data,
  }
  knot::tsig { $name:
    algo => $algo,
    data => $data,
  }
}
