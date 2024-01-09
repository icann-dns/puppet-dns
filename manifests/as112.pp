# dns::as112
#
# @summary configure and as112 server
class dns::as112 {
  include dns
  include "${dns::daemon}:as112"
}
