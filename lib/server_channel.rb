module Rakie
  class ServerChannel
    def initialize(ip, port)
      @server = Server.new(ip, port)
    end
    
    def self.accept(io)
      
    end
  end
end