module Rakie
  class SimpleHttpServer
    def initialize(host: '0.0.0.0', port: 3001)
      @server = HttpServer.new(host, port, self)
    end
  end
end