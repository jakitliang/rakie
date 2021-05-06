module Rakie
  class WebsocketServer
    class Session
      # @return [Array<WebsocketMessage>]
      attr_accessor :requests

      # @type [Array<WebsocketMessage>]
      attr_accessor :responses

      def initialize
        @requests = []
        @responses = []
      end
    end

    def initialize(delegate=nil, channel=nil)
      @channel = channel

      if channel == nil
        @channel = TCPServerChannel.new('127.0.0.1', 10086, self)
      end

      # @type [Hash{Channel=>Session}]
      @sessions = {}
      @delegate = delegate
    end

    def on_accept(channel)
      channel.delegate = self
      @sessions[channel] = Session.new
      Log.debug("Rakie::WebsocketServer accept client: #{channel}")
    end

    def on_recv(channel, data)
      # Log.debug("Rakie::HTTPServer recv: #{data}")
      session = @sessions[channel]

      # @type [WebsocketMessage] request
      request = session.requests[-1]

      if request == nil
        request = WebsocketMessage.new
        session.requests << request

      elsif request.parse_status == ParseStatus::COMPLETE
        request = WebsocketMessage.new
        session.requests << request
      end

      len = request.parse(data)

      Log.debug("Rakie::WebsocketServer receive request: #{request.payload}")

      if request.parse_status == ParseStatus::COMPLETE
        response = WebsocketMessage.new

        if request.op_code == WebsocketMessage::OP_PING
          response.fin = true
          response.op_code = WebsocketMessage::OP_PONG
          response.payload = "pong"

        elsif request.op_code == WebsocketMessage::OP_PONG
          response.fin = true
          response.op_code = WebsocketMessage::OP_PING
          response.payload = "ping"

        elsif @delegate != nil
          response.payload = @delegate.handle(request.payload)

        else
          response.payload = "Rakie!"
        end
        
        response_data = response.to_s

        Log.debug("Rakie::WebsocketServer response: #{response_data}")

        channel.write(response_data) # Response data

      elsif request.parse_status == ParseStatus::ERROR
        channel.close
        @sessions.delete(channel)

        Log.debug("Rakie::WebsocketServer: Illegal request")
        return len
      end

      return len
    end

    def on_send(channel)
      session = @sessions[channel]
      # @type [WebsocketMessage]
      last_request = session.requests.shift

      if last_request
        if last_request.op_code == WebsocketMessage::OP_CLOSE
          Log.debug("Rakie::WebsocketServer: send finish and close channel")
          channel.close
        end
      end
    end
  end
end