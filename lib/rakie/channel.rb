module Rakie
  class Channel
    attr_accessor :delegate

    def initialize(io, delegate=nil)
      @io = io
      @read_buffer = String.new
      @write_buffer = String.new
      @delegate = delegate
      Event.push(io, self, Event::READ_EVENT)
    end

    def on_read(io)
      begin
        loop do
          @read_buffer << io.read_nonblock(4096)
        end

      rescue IO::EAGAINWaitReadable
        puts("Channel read finished")

      rescue
        # Process the last message on exception
        if @delegate != nil
          @delegate.on_recv(self, @read_buffer)
          @read_buffer = String.new # Reset buffer
        end

        puts("Channel error #{io}")
        return Event::HANDLE_FAILED
      end

      puts("Channel has delegate?: #{@delegate}")
      if @delegate != nil
        len = @delegate.on_recv(self, @read_buffer)

        if len > @read_buffer.length
          len = @read_buffer.length
        end

        @read_buffer = @read_buffer[len .. -1]
        puts("Channel handle on_recv")
      end

      return Event::HANDLE_CONTINUED
    end

    def on_write(io)
      begin
        while @write_buffer.length > 0
          len = io.write_nonblock(@write_buffer)
          @write_buffer = @write_buffer[len .. -1]
        end

        puts("Channel write finished")

      rescue IO::EAGAINWaitWritable
        puts("Channel write continue")
        return Event::HANDLE_CONTINUED

      rescue
        puts("Channel close #{io}")
        return Event::HANDLE_FAILED
      end

      return Event::HANDLE_FINISHED
    end

    def on_close(io)
      begin
        io.close

      rescue
        puts("Channel is already closed")
      end
    end

    def read(size)
      if self.eof?
        return ""
      end

      if size > data.length
        size = data.length
      end

      data = @read_buffer[0 .. (size - 1)]
      @read_buffer = @read_buffer[size .. -1]

      return data
    end

    def write(data)
      if @io.closed?
        return -1
      end

      @write_buffer << data
      Event.modify(@io, self, Event::READ_EVENT | Event::WRITE_EVENT)

      return 0
    end

    def close
      if @io.closed?
        return nil
      end

      Event.delete(@io)
      return nil
    end

    def eof?
      @read_buffer.empty?
    end

    def closed?
      @io.closed?
    end
  end
end
