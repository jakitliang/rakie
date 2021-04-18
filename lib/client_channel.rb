module Rakie
  class ClientChannel
    def initialize(ip, port=nil)
      if ip.is_a?(IO)
        @client = ip
        return
      end

      @client = TCPSocket.new(ip, port)
    end

    def self.read(channels, size=nil)
      @event.read(channels, size)
    end

    def self.write(channels, buffers)
      @event.write(channels, buffers)
    end
  end
end