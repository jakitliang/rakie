module Rakie
  class Websocket
    attr_accessor :delegate, :client_side
    attr_reader :channel

    # @param [Rakie::TCPChannel] channel
    def initialize(delegate=nil, channel=nil)
      @delegate = delegate

      if channel == nil
        channel = TCPChannel.new('127.0.0.1', 10086, self)        
      end

      @channel = channel

      # @type [WebsocketMessage]
      @recv_message = WebsocketMessage.new

      # @type [Array<WebsocketMessage>]
      @send_messages = []
      @client_side = true
    end

    # @param [String] data
    def on_recv(channel, data)
      Log.debug("Rakie::Websocket recv: #{data}")

      total_parsed = 0

      while data.length > 0
        # @type [WebsocketMessage] request
        message = @recv_message

        if message.parse_status == ParseStatus::COMPLETE
          message = WebsocketMessage.new
          @recv_message = message
        end

        len = message.parse(data)
        total_parsed += len

        Log.debug("Rakie::Websocket receive message: #{message.to_s} parse with #{len}")

        if message.parse_status == ParseStatus::COMPLETE
          response = WebsocketMessage.new

          if message.op_code == WebsocketMessage::OP_PING
            response.fin = true
            response.op_code = WebsocketMessage::OP_PONG
            response.payload = "Rakie::Websocket: op pong"

          elsif message.op_code == WebsocketMessage::OP_PONG
            response.fin = true
            response.op_code = WebsocketMessage::OP_PING
            response.payload = "Rakie::Websocket: op ping"

          elsif message.op_code == WebsocketMessage::OP_CLOSE
            channel.close

            Log.debug("Rakie::Websocket: op close")
            return 0

          elsif @delegate
            @delegate.on_message(self, message.payload)

          else
            response.fin = true
            response.op_code = WebsocketMessage::OP_TEXT
            response.payload = "Rakie!"
          end
          
          response_data = response.to_s

          Log.debug("Rakie::Websocket response: #{response_data}")

          channel.write(response_data) # Response data

        elsif message.parse_status == ParseStatus::CONTINUE
          break
          
        elsif message.parse_status == ParseStatus::ERROR
          channel.close

          Log.debug("Rakie::Websocket: Illegal message")
          return 0
        end

        if len >= data.length
          break
        end

        data = data[len .. -1]
      end

      return total_parsed
    end

    def on_send(channel)
      # @type [WebsocketMessage]
      last_message = @send_messages.shift

      if last_message
        if last_message.op_code == WebsocketMessage::OP_CLOSE
          Log.debug("Rakie::Websocket: send finish and close channel")
          channel.close
        end
      end
    end

    def on_close(channel)
      if @delegate
        @delegate.on_disconnect(self)
      end
    end

    def send(message, is_binary=false)
      ws_message = WebsocketMessage.new
      ws_message.fin = true
      ws_message.op_code = WebsocketMessage::OP_TEXT
      ws_message.payload = message

      if is_binary
        ws_message.op_code = WebsocketMessage::OP_BIN
      end

      if @client_side
        ws_message.mask = true
        ws_message.refresh_masking
      end

      send_message = ws_message.to_s
      @send_messages << ws_message

      Log.debug("Rakie::Websocket send: #{send_message}")

      @channel.write(send_message) # Response data
    end

    def close
      ws_message = WebsocketMessage.new
      ws_message.fin = true
      ws_message.op_code = WebsocketMessage::OP_CLOSE

      if @client_side
        ws_message.mask = true
        ws_message.refresh_masking
      end

      ws_message.payload = "close"

      send_message = ws_message.to_s

      Log.debug("Rakie::Websocket send close: #{send_message}")

      @channel.write(send_message) # Response data
    end
  end
end
