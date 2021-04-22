module Rakie
  class HTTPServer
    PARSE_ERROR = -1
    PARSE_OK = 0
    PARSE_PENDING = 1
    PARSE_COMPLETE = 2

    PARSE_HEAD = 0
    PARSE_HEADERS = 1
    PARSE_CONTENT = 2

    class MIME
      TEXT = "text/plain"
      HTML = "text/html"
      JSON = "application/json"
    end

    def initialize(delegate=nil)
      @channel = TCPServerChannel.new('127.0.0.1', 10086, self)
      @clients = {}
      @delegate = delegate
    end

    def on_accept(channel)
      channel.delegate = self
      @clients[channel] = {
        :parse_status => PARSE_HEAD,
        :parse_offset => 0,
        :request => {
          :head => {
            :method => "HEAD",
            :path => "/",
            :version => "HTTP/1.1"
          },
          :headers => {},
          :content => ""
        },
        :response => {
          :head => {
            :version => "HTTP/1.1",
            :status => 200,
            :message => "OK"
          },
          :headers => {},
          :content => ""
        }
      }
      Log.debug("Rakie::HTTPServer accept client: #{channel}")
    end

    def parse_data_head(client, data)
      if eol_offset = data.index("\r\n")
        head = data[0 .. eol_offset]
        head_method, head_path, head_version = head.split(' ')
        client[:request][:head][:method] = head_method
        client[:request][:head][:path] = head_path
        client[:request][:head][:version] = head_version
        client[:parse_status] = PARSE_HEADERS
        client[:parse_offset] += eol_offset + 2

        Log.debug("Rakie::HTTPServer parse data head ok")
        return PARSE_OK
      end

      return PARSE_PENDING
    end

    def parse_data_header_item(header)
      if semi_offset = header.index(':')
        return [header[0 .. (semi_offset - 1)].downcase, header[semi_offset .. -1].strip.downcase]
      end
      
      return nil
    end

    def parse_data_headers(client, data)
      offset = client[:parse_offset]

      while eol_offset = data.index("\r\n", offset)
        header = data[offset .. (eol_offset - 1)]

        if header.length == 0
          client[:parse_status] = PARSE_CONTENT
          client[:parse_offset] += eol_offset + 2

          Log.debug("Rakie::HTTPServer parse data header done")
          return PARSE_OK
        end

        header_key, header_value = self.parse_data_header_item(header)

        if header_key
          client[:request][:headers][header_key] = header_value
          offset += eol_offset + 2

          Log.debug("Rakie::HTTPServer parse data header ok")
        end

        offset = eol_offset + 2
      end

      client[:parse_offset] = offset

      return PARSE_PENDING
    end

    def parse_data_content(client, data)
      len = client[:request][:headers]["content-length"]
      offset = client[:parse_offset]

      if len == nil
        return PARSE_COMPLETE
      end

      if data.length >= len + offset
        client[:request][:content] = data[offset .. (offset + len - 1)]
        client[:parse_status] = PARSE_HEAD
        client[:parse_offset] = offset + len

        Log.debug("Rakie::HTTPServer parse data content ok")
        return PARSE_COMPLETE
      end

      return PARSE_PENDING
    end

    def parse_data(client, data)
      result = PARSE_OK

      while result == PARSE_OK
        current_status = client[:parse_status]

        case current_status
        when PARSE_HEAD
          result = self.parse_data_head(client, data)

        when PARSE_HEADERS
          result = self.parse_data_headers(client, data)

        when PARSE_CONTENT
          result = self.parse_data_content(client, data)
        end
      end

      Log.debug("Rakie::HTTPServer parse data result #{result}")

      return result
    end

    def pack_data(response)
      data = ""

      response[:headers]["content-length"] = response[:content].length
      response[:headers]["server"] = "Rakie 0.0.2"

      data += response[:head].values.join(' ')
      data += "\r\n"

      headers = []
      response[:headers].each do |k, v|
        headers << "#{k}: #{v}"
      end

      data += headers.join("\r\n")
      data += "\r\n\r\n"

      data += response[:content]
    end

    def on_recv(channel, data)
      # Log.debug("Rakie::HTTPServer recv: #{data}")
      client = @clients[channel]
      client[:parse_offset] = 0
      result = self.parse_data(client, data)

      req = client[:request]
      Log.debug("Rakie::HTTPServer receive request: #{req}")

      if result == PARSE_COMPLETE
        if @delegate != nil
          @delegate.handle(client[:request], client[:response])

        else
          client[:response][:headers]["content-type"] = MIME::HTML
          client[:response][:content] = "<html><body><h1>Rakie!</h1></body></html>"
        end
        
        response_data = self.pack_data(client[:response])

        # p response_data

        channel.write(response_data) # Response data

      elsif result == PARSE_ERROR
        channel.close
        @clients.delete(channel)

        Log.debug("Rakie::HTTPServer: Illegal request")
        return client[:parse_offset]
      end

      return client[:parse_offset]
    end

    def on_send(channel)
      client = @clients[channel]

      if client[:request][:headers]["connection"] == "close"
        channel.close
      end
    end
  end
end

require "pp"