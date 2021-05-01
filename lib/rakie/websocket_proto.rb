module Rakie
  class WebsocketMessage
    include Proto

    FLAG_FIN = 1 << 7

    OP_CONTINUE = 0x0
    OP_TEXT = 0x1
    OP_BIN = 0x2
    OP_CLOSE = 0x8
    OP_PING = 0x9
    OP_PONG = 0xA

    FLAG_MASK = 1 << 7

    PARSE_OPERATION = PARSE_BEGIN
    PARSE_LEN = 1
    PARSE_EXT_LEN = 2
    PARSE_MASKING = 3
    PARSE_PAYLOAD = 4

    attr_accessor :op_code, :mask, :length, :payload

    def initialize
      @fin = false
      @op_code = 0x0
      @mask = false
      @length = 0
      @long_ext = false
      @payload = ''
    end

    # @param [String] source
    def parse_source_operation(source)
      offset = parse_offset

      if source.length >= 1 + offset
        byte = source[0]
        data = byte.unpack('C')[0]

        if data & FLAG_FIN > 0
          @fin = true
        end

        i = 3
        code = 0x0

        while i >= 0
          code |= data & (1 << i)
          i -= 1
        end

        @op_code = code

        self.parse_state = PARSE_LEN
        self.parse_offset = offset + 1

        Log.debug("Rakie::HttpRequest parse source head ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_len(source)
      offset = parse_offset

      if source.length >= 1 + offset
        byte = source[0]
        data = byte.unpack('C')[0]

        if data & FLAG_MASK > 0
          @mask = true
        end

        len = data & ~FLAG_MASK

        if len <= 125
          @length = len

          if @mask
            self.parse_state = PARSE_MASKING
            self.parse_offset = offset + 1

            Log.debug("Rakie::HttpRequest parse source head ok")
            return ParseStatus::CONTINUE
          end

          self.parse_state = PARSE_PAYLOAD
          self.parse_offset = offset + 1

          Log.debug("Rakie::HttpRequest parse source head ok")
          return ParseStatus::CONTINUE
        end

        if len == 127
          @long_ext = true
        end

        self.parse_state = PARSE_EXT_LEN
        self.parse_offset = offset + 1

        Log.debug("Rakie::HttpRequest parse source head ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_ext_len(source)
      offset = parse_offset
      ext_len_size = 2

      if @long_ext
        ext_len_size = 8
      end

      if source.length >= ext_len_size + offset
        bytes = source[0 .. ext_len_size]
        @length = bytes.unpack('Q>')[0]

        if @mask
          self.parse_state = PARSE_MASKING
          self.parse_offset = offset + ext_len_size

          Log.debug("Rakie::HttpRequest parse source head ok")
          return ParseStatus::CONTINUE
        end

        self.parse_state = PARSE_PAYLOAD
        self.parse_offset = offset + ext_len_size

        Log.debug("Rakie::HttpRequest parse source head ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_masking(source)
      offset = parse_offset

      if source.length >= 4 + offset
        bytes = source[0 .. 3]
        @masking = bytes.unpack('C*')

        self.parse_state = PARSE_PAYLOAD
        self.parse_offset = offset + 4

        Log.debug("Rakie::HttpRequest parse source head ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_payload(source)
      offset = parse_offset

      if source.length >= @length + offset
        bytes = source[0 .. (@length - 1)]
        bytes_list = bytes.unpack('C*')

        masking = @masking
        bytes_list_unmasked = bytes_list.map.with_index { |b, i| b ^ masking[i % 4] }

        @payload = bytes_list_unmasked.pack('C*')

        self.parse_state = PARSE_OPERATION
        self.parse_offset = offset + @length

        Log.debug("Rakie::HttpRequest parse source head ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def deserialize(source)
      current_state = parse_state

      case current_state
      when PARSE_OPERATION
        return parse_source_operation(source)

      when PARSE_LEN
        return parse_source_len(source)

      when PARSE_EXT_LEN
        return parse_source_ext_len(source)

      when PARSE_MASKING
        return parse_source_masking(source)

      when PARSE_PAYLOAD
        return parse_source_payload(source)
      end
    end

    def serialize
      
    end
  end

  class WebsocketProto
    PARSE_HEAD = 0
    PARSE_HEADERS = 1

    def initialize
      @request = WebsocketMessage.new
      @response = WebsocketMessage.new
    end

    # @param [WebsocketMessage] message
    def pack_message(message)
      message_s = ''

      fin = message.fin ? 1 : 0
      message_s << (fin << 7) + message.payload.length
      message.payload.length
    end


  end
end