module Rakie
  class TCPChannel < Channel
    def initialize(ip, port, delegate=nil)
      @io = TCPSocket.new(ip, port)
      super(@io, delegate)
    end
  end
end

require "socket"