# noodleparam Puppet function
#
# Two required arguments: HOST and PARAM
#
# Third optional argument SERVER which should be the Noodle server:port
#
# Returns value of PARAM for HOST

require_relative './../../../../../../lib/noodle/client'

module Puppet::Parser::Functions
  newfunction(:noodleparam, :type => :rvalue) do |args|
    host   = args[0]
    param  = args[1]
    server = args[2]
    Noodle.paramvalue(host,param,server)
  end
end
