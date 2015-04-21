# noodlemagic Puppet function
#
# First argument QUERY is required
#
# Second optional argument SERVER which should be the Noodle server:port
#
# Returns an array containing the query result split on \n
require_relative './../../../../../../lib/noodle/client'

module Puppet::Parser::Functions
  newfunction(:noodlemagic, :type => :rvalue) do |args|
    query  = args[0]
    server = args[1]
    Noodle.magic(query,server).split("\n")
  end
end
