require "socket"
require "channel"

module Rakie
  class TCPServerChannel < Channel
    def initialize(ip, port=nil, delegate=nil)
      io = nil
      
      if port == nil
        port = ip
        io = TCPServer.new(ip)

      else
        io = TCPServer.new(ip, port)
      end
      
      @clients = []

      super(io, delegate)
    end

    def on_read(io)
      begin
        client_io, = io.accept_nonblock
        channel = Channel.new(client_io)

        if @delegate != nil
          puts("TCPServerChannel has delegate")
          @delegate.on_accept(channel)

        else
          puts("TCPServerChannel no delegate")
          @clients << channel
        end

        puts("TCPServerChannel accept #{channel}")

      rescue IO::EAGAINWaitReadable
        puts("TCPServerChannel accept wait")

      rescue
        puts("TCPServerChannel Accept failed #{io}")
        return Event::HANDLE_FAILED
      end

      return Event::HANDLE_CONTINUED
    end

    def accept
      @clients.shift
    end
  end
end