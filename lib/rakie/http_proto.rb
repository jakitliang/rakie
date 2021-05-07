module Rakie
  class HttpMIME
    TEXT = "text/plain"
    HTML = "text/html"
    JSON = "application/json"
  end

  class HttpRequest
    include Proto

    attr_accessor :head, :headers, :content

    PARSE_HEAD = PARSE_BEGIN
    PARSE_HEADERS = 1
    PARSE_CONTENT = 2

    class Head
      attr_accessor :method, :path, :version

      def initialize
        @method = 'HEAD'
        @path = '/'
        @version = 'HTTP/1.1'
      end
    end

    def initialize
      @head = Head.new
      @headers = {}
      @content = ''
    end

    # @param [String] source
    def parse_source_head(source)
      offset = parse_offset

      if eol_offset = source.index("\r\n")
        head_s = source[0 .. eol_offset]
        head_method, head_path, head_version = head_s.split(' ')

        head.method = head_method
        head.path = head_path
        head.version = head_version

        self.parse_state = PARSE_HEADERS
        self.parse_offset = offset + 2

        Log.debug("Rakie::HttpRequest parse source head ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    def parse_source_header_item(header)
      if semi_offset = header.index(':')
        return [
          header[0 .. (semi_offset - 1)].downcase,
          header[(semi_offset + 1) .. -1].strip
        ]
      end
      
      return nil
    end

    # @param [String] source
    def parse_source_headers(source)
      offset = parse_offset

      while eol_offset = source.index("\r\n", offset)
        header = source[offset .. (eol_offset - 1)]

        if header.length == 0
          self.parse_state = PARSE_CONTENT
          self.parse_offset = eol_offset + 2

          Log.debug("Rakie::HttpRequest parse source header done")
          return ParseStatus::CONTINUE
        end

        header_key, header_value = self.parse_source_header_item(header)

        if header_key
          headers[header_key] = header_value
          Log.debug("Rakie::HttpRequest parse source #{header_key}, #{header_value} header ok")
        end

        offset = eol_offset + 2
      end

      self.parse_offset = offset

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_content(source)
      len = headers["content-length"]
      offset = parse_offset

      if len == nil
        return ParseStatus::COMPLETE
      end

      len = len.to_i

      if source.length >= len + offset
        self.content = source[offset .. (offset + len - 1)]
        self.parse_state = PARSE_HEAD
        self.parse_offset = offset + len

        Log.debug("Rakie::HttpRequest parse source content ok")
        return ParseStatus::COMPLETE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    # @return [Integer]
    def deserialize(source)
      current_state = parse_state

      case current_state
      when PARSE_HEAD
        return parse_source_head(source)

      when PARSE_HEADERS
        return parse_source_headers(source)

      when PARSE_CONTENT
        return parse_source_content(source)
      end
    end

    # @return [String]
    def serialize
      data = ""

      data += "#{head.method} #{head.path} #{head.version}"
      data += "\r\n"

      headers_list = []
      headers.each do |k, v|
        headers_list << "#{k}: #{v}"
      end

      data += headers_list.join("\r\n")
      data += "\r\n\r\n"

      data += content
    end
  end

  class HttpResponse
    include Proto

    PARSE_HEAD = 0
    PARSE_HEADERS = 1
    PARSE_CONTENT = 2

    attr_accessor :head, :headers, :content

    class Head
      attr_accessor :version, :status, :message

      def initialize
        @version = 'HTTP/1.1'
        @status = 200
        @message = 'OK'
      end
    end

    def initialize
      @head = Head.new
      @headers = {}
      @content = ''
    end

    def serialize
      data = ""

      data += "#{head.version} #{head.status} #{head.message}"
      data += "\r\n"

      headers_list = []
      headers.each do |k, v|
        headers_list << "#{k}: #{v}"
      end

      data += headers_list.join("\r\n")
      data += "\r\n\r\n"

      data += content
    end
  end
end