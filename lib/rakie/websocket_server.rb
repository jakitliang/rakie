module Rakie
  class WebsocketServer < Websocket
    # @param [Rakie::HttpServer] http_server
    def initialize(delegate=nil, http_server=nil)
      @delegate = delegate

      if http_server == nil
        http_server = HttpServer.new('127.0.0.1', 10086, self)
      end

      http_server.opt[:websocket_delegate] = self
      @channel = http_server.channel

      # @type [Array<WebsocketClient>]
      @clients = []
    end

    def on_accept(channel)
      ws_client = Websocket.new(self, channel)

      if @delegate
        @delegate.on_register(ws_client)
        return
      end

      @clients << ws_client
      Log.debug("Rakie::WebsocketServer accept client: #{ws_client}")
    end

    def on_message(client, message)
      if @delegate
        @delegate.on_message(client, message)
      end
    end

    # @param [HttpRequest] request
    # @param [HttpResponse] response
    # @return bool
    def upgrade(request, response)
      if websocket_key = request.headers["sec-websocket-key"]
        digest_key = Digest::SHA1.base64digest(websocket_key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')

        response.head.status = 101
        response.head.message = 'Switching Protocols'
        response.headers["connection"] = "upgrade"
        response.headers["upgrade"] = "websocket"
        response.headers["sec-websocket-accept"] = digest_key
      end
    end

    def send(message, is_binary=false); end

    def close
      @clients.each do |client|
        ws_message = WebsocketMessage.new
        ws_message.fin = true
        ws_message.op_code = WebsocketMessage::OP_CLOSE
        ws_message.payload = "close"

        send_message = ws_message.to_s

        Log.debug("Rakie::Websocket send close: #{send_message}")

        @channel.write(send_message) # Response data
      end
    end
  end
end

require "digest"
require "base64"