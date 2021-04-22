module Rakie
  class SimpleServer
    PARSE_ERROR = -1
    PARSE_OK = 0
    PARSE_PENDING = 1
    PARSE_COMPLETE = 2

    PARSE_TYPE = 0
    PARSE_LEN = 1
    PARSE_ENTITY = 2

    def initialize(delegate=nil)
      @channel = TCPServerChannel.new('127.0.0.1', 10086, self)
      @clients = {}
      @delegate = delegate
    end

    def on_accept(channel)
      channel.delegate = self
      @clients[channel] = {
        :parse_status => PARSE_TYPE,
        :parse_offset => 0,
        :request => {
          :type => 0,
          :len => 0,
          :entity => ""
        },
        :response => {
          :type => 0,
          :len => 0,
          :entity => ""
        }
      }
      Log.debug("SimpleServer accept client: #{channel}")
    end

    def parse_data_type(client, data)
      if data.length >= 1
        type = data[0].ord
        client[:request][:type] = type
        client[:parse_status] = PARSE_LEN
        client[:parse_offset] += 1

        Log.debug("SimpleServer parse data type ok")
        return PARSE_OK
      end

      return PARSE_PENDING
    end

    def parse_data_len(client, data)
      offset = client[:parse_offset]

      if data.length >= 4 + offset
        len = data[offset .. (4 + offset - 1)]
        len = len.unpack('l')[0]

        if len == nil
          return PARSE_ERROR
        end

        client[:request][:len] = len
        client[:parse_status] = PARSE_ENTITY
        client[:parse_offset] = offset + 4

        Log.debug("SimpleServer parse data len ok")
        return PARSE_OK
      end

      return PARSE_PENDING
    end

    def parse_data_entity(client, data)
      len = client[:request][:len]
      offset = client[:parse_offset]

      if data.length >= len + offset
        client[:request][:entity] = data[offset .. (offset + len - 1)]
        client[:parse_status] = PARSE_TYPE
        client[:parse_offset] = offset + len

        Log.debug("SimpleServer parse data entity ok")
        return PARSE_COMPLETE
      end

      return PARSE_PENDING
    end

    def parse_data(client, data)
      result = PARSE_OK

      while result == PARSE_OK
        current_status = client[:parse_status]

        case current_status
        when PARSE_TYPE
          result = self.parse_data_type(client, data)

        when PARSE_LEN
          result = self.parse_data_len(client, data)

        when PARSE_ENTITY
          result = self.parse_data_entity(client, data)
        end
      end

      Log.debug("SimpleServer parse data result #{result}")

      return result
    end

    def pack_data(response)
      data = ""
      data += [response[:type]].pack('c')
      data += [response[:len]].pack('l')
      data += response[:entity]
    end

    def on_recv(channel, data)
      Log.debug("SimpleServer recv: #{data}")
      client = @clients[channel]
      client[:parse_offset] = 0
      result = self.parse_data(client, data)

      if result == PARSE_COMPLETE
        if @delegate != nil
          @delegate.handle(client[:request], client[:response])

        else
          client[:response] = client[:request]
        end
        
        channel.write(self.pack_data(client[:response])) # Response data

      elsif result == PARSE_ERROR
        channel.close
        @clients.delete(channel)
        Log.debug("SimpleServer: Illegal request")
        return client[:parse_offset]
      end

      return client[:parse_offset]
    end
  end
end
