module Rakie
  class WebsocketBasicMessage
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
    attr_writer :fin

    def initialize
      @fin = false
      @op_code = 0x0
      @mask = false
      @masking = []
      @length = 0
      @long_ext = false
      @payload = ''
    end

    def fin?
      @fin
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
      data = ''

      data += pack_source_operation
      data += pack_source_len

      if @mask
        data += pack_source_masking
        data += pack_source_masked_payload

        return data
      end

      data += @payload

      return data
    end
  end
  
  class WebsocketMessage < WebsocketBasicMessage
    # @param [String] source
    def parse_source_operation(source)
      offset = parse_offset

      if source.length >= 1 + offset
        byte = source[offset]
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

        Log.debug("Rakie::WebsocketMessage parse source operation ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_len(source)
      offset = parse_offset

      if source.length >= 1 + offset
        byte = source[offset]
        data = byte.unpack('C')[0]

        if data & FLAG_MASK > 0
          @mask = true
        end

        len = data & ~FLAG_MASK

        Log.debug("Rakie::WebsocketMessage len: #{len}")

        if len <= 125
          @length = len

          if @mask
            self.parse_state = PARSE_MASKING
            self.parse_offset = offset + 1

            Log.debug("Rakie::WebsocketMessage parse source len ok")
            return ParseStatus::CONTINUE
          end

          self.parse_state = PARSE_PAYLOAD
          self.parse_offset = offset + 1

          Log.debug("Rakie::WebsocketMessage parse source len ok")
          return ParseStatus::CONTINUE
        end

        if len == 127
          @long_ext = true
        end

        self.parse_state = PARSE_EXT_LEN
        self.parse_offset = offset + 1

        Log.debug("Rakie::WebsocketMessage parse source len ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_ext_len(source)
      offset = parse_offset
      ext_len_size = 2
      byte_format = 'S'

      if @long_ext
        ext_len_size = 8
        byte_format = 'Q'
      end

      if source.length >= ext_len_size + offset
        bytes = source[offset .. (offset + ext_len_size - 1)]
        @length = bytes.unpack(byte_format + '>')[0]

        if @mask
          self.parse_state = PARSE_MASKING
          self.parse_offset = offset + ext_len_size

          Log.debug("Rakie::WebsocketMessage parse source ext len ok")
          return ParseStatus::CONTINUE
        end

        self.parse_state = PARSE_PAYLOAD
        self.parse_offset = offset + ext_len_size

        Log.debug("Rakie::WebsocketMessage parse source ext len ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_masking(source)
      offset = parse_offset

      if source.length >= 4 + offset
        bytes = source[offset .. (offset + 4 - 1)]
        @masking = bytes.unpack('C*')

        self.parse_state = PARSE_PAYLOAD
        self.parse_offset = offset + 4

        Log.debug("Rakie::WebsocketMessage parse source masking ok")
        return ParseStatus::CONTINUE
      end

      return ParseStatus::PENDING
    end

    # @param [String] source
    def parse_source_payload(source)
      offset = parse_offset

      if source.length >= @length + offset
        bytes = source[offset .. (offset + @length - 1)]

        if @mask
          bytes_list = bytes.unpack('C*')
          masking = @masking
          bytes_list_unmasked = bytes_list.map.with_index { |b, i| b ^ masking[i % 4] }

          @payload = bytes_list_unmasked.pack('C*')

          self.parse_state = PARSE_OPERATION
          self.parse_offset = offset + @length

          Log.debug("Rakie::WebsocketMessage parse source masked payload ok")
          return ParseStatus::COMPLETE
        end

        @payload = bytes

        self.parse_state = PARSE_OPERATION
        self.parse_offset = offset + @length

        Log.debug("Rakie::WebsocketMessage parse source payload ok")
        return ParseStatus::COMPLETE
      end

      return ParseStatus::PENDING
    end

    def pack_source_operation
      fin_bit = @fin ? 1 : 0
      return [(fin_bit << 7) + @op_code].pack('C')
    end

    def pack_source_len
      mask_bit = @mask ? 1 : 0

      if @payload.length < 126
        return [(mask_bit << 7) + @payload.length].pack('C')

      elsif @payload.length < 65536
        return [(mask_bit << 7) + 126, @payload.length].pack('CS>')
      end

      return [(mask_bit << 7) + 127, @payload.length].pack('CQ>')
    end

    def pack_source_masking
      return @masking.pack('C*')
    end

    def pack_source_masked_payload
      masking = @masking

      if masking.empty?
        return ''
      end

      bytes_list = @payload.unpack('C*')
      bytes_list_masked = bytes_list.map.with_index { |b, i| b ^ masking[i % 4] }
      
      return bytes_list_masked.pack('C*')
    end

    def refresh_masking
      masking = []
      4.times { masking << rand(1 .. 255) }
      @masking = masking
    end
  end
end