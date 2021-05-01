module Rakie
  class WebServer
    class Session
      # @return [Array<HttpRequest>]
      attr_accessor :requests

      # @type [Array<HttpResponse>]
      attr_accessor :responses

      def initialize
        @requests = []
        @responses = []
      end
    end

    def initialize(delegate=nil)
      @channel = TCPServerChannel.new('127.0.0.1', 10086, self)

      # @type [Hash{Channel=>Session}]
      @sessions = {}
      @delegate = delegate
    end

    def on_accept(channel)
      channel.delegate = self
      @sessions[channel] = Session.new
      Log.debug("Rakie::HTTPServer accept client: #{channel}")
    end

    def on_recv(channel, data)
      # Log.debug("Rakie::HTTPServer recv: #{data}")
      session = @sessions[channel]

      # @type [HttpRequest] request
      request = session.requests[-1]

      if request == nil
        request = HttpRequest.new
        session.requests << request

      elsif request.parse_status == ParseStatus::COMPLETE
        request = HttpRequest.new
        session.requests << request
      end

      len = request.parse(data)

      Log.debug("Rakie::WebServer receive request: #{request.to_s}")

      if request.parse_status == ParseStatus::COMPLETE
        response = HttpResponse.new

        if @delegate != nil
          @delegate.handle(request, response)

        else
          response.headers["content-type"] = HttpMIME::HTML
          response.content = "<html><body><h1>Rakie!</h1></body></html>"
        end
        
        response.headers["content-length"] = response.content.length
        response.headers["server"] = Rakie.full_version_s

        response_data = response.to_s

        Log.debug("Rakie::WebServer response: #{response_data}")

        channel.write(response_data) # Response data

      elsif request.parse_status == ParseStatus::ERROR
        channel.close
        @sessions.delete(channel)

        Log.debug("Rakie::WebServer: Illegal request")
        return len
      end

      return len
    end

    def on_send(channel)
      session = @sessions[channel]
      # @type [HttpRequest]
      last_request = session.requests.shift

      if last_request
        if last_request.headers["connection"] == "close"
          Log.debug("Rakie::WebServer: send finish and close channel")
          channel.close
        end
      end
    end
  end
end

require "pp"