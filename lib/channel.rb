module Rakie
  class Channel
    def initialize(ip, port)
      @server = Server.new(ip, port)
    end

    def on_accept(io, data)
      
    end

    def on_read(io, data)
      
    end

    def on_write(size)
      return '123456'
    end

    def on_close(io)
      
    end

    def self.accept(io)
      
    end

    def self.read(ios, size=nil)
      @server.read(ios, size)
    end

    def self.write(ios, buffers)
      @server.write(ios, buffers)
    end
  end
end