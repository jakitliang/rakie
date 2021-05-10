module Rakie
  class HttpServer
    class Session
      # @return [HttpRequest]
      attr_accessor :request

      # @type [Array<HttpResponse>]
      attr_accessor :responses

      def initialize
        @request = HttpRequest.new
        @responses = []
      end
    end

    attr_reader :channel, :opt

    def initialize(delegate=nil)
      @channel = TCPServerChannel.new('127.0.0.1', 10086, self)

      # @type [Hash{Channel=>Session}]
      @sessions = {}
      @delegate = delegate
      @opt = {}
    end

    def on_accept(channel)
      channel.delegate = self
      @sessions[channel] = Session.new
      Log.debug("Rakie::HTTPServer accept client: #{channel}")
    end

    def on_recv(channel, data)
      # Log.debug("Rakie::HTTPServer recv: #{data}")
      session = @sessions[channel]

      if session == nil
        return 0
      end

      # @type [HttpRequest] request
      request = session.request

      if request.parse_status == ParseStatus::COMPLETE
        request = HttpRequest.new
        session.request = request
      end

      len = request.parse(data)

      Log.debug("Rakie::HttpServer receive request: #{request.to_s}")

      if request.parse_status == ParseStatus::COMPLETE
        response = HttpResponse.new

        if upgrade = request.headers["upgrade"]
          if websocket_delegate = @opt[:websocket_delegate]
            websocket_delegate.upgrade(request, response)
            Log.debug("Rakie::HttpServer upgrade protocol")
          end

        elsif @delegate != nil
          @delegate.handle(request, response)

        else
          response.headers["content-type"] = HttpMIME::HTML
          response.content = "<html><body><h1>Rakie!</h1></body></html>"
        end
        
        if header_connection = request.headers["connection"]
          response.headers["connection"] = header_connection
        end

        if response.content.length > 0
          response.headers["content-length"] = response.content.length
        end

        response.headers["server"] = Rakie.full_version_s
        session.responses << response
        response_data = response.to_s

        Log.debug("Rakie::HttpServer response: #{response_data}")

        channel.write(response_data) # Response data

      elsif request.parse_status == ParseStatus::ERROR
        channel.close
        @sessions.delete(channel)

        Log.debug("Rakie::HttpServer: Illegal request")
        return len
      end

      return len
    end

    def on_send(channel)
      session = @sessions[channel]
      # @type [HttpRequest]
      last_response = session.responses.shift

      if last_response
        if connect_status = last_response.headers["connection"]
          if connect_status.downcase == "close"
            Log.debug("Rakie::HttpServer: send finish and close channel")
            channel.close
            @sessions.delete(channel)
          end
        end

        if upgrade = last_response.headers["upgrade"]
          websocket_delegate = @opt[:websocket_delegate]

          if websocket_delegate
            websocket_delegate.on_accept(channel)
            @sessions.delete(channel)
            return
          end

          Log.debug("Rakie::HttpServer: no websocket delegate and close channel")
          channel.close
          @sessions.delete(channel)
        end
      end
    end
  end
end