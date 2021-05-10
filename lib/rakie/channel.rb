module Rakie
  class Channel
    attr_accessor :delegate

    DEFAULT_BUFFER_SIZE = 512 * 1024

    def initialize(io, delegate=nil)
      @io = io
      @read_buffer = String.new
      @write_buffer = String.new
      @write_task = []
      @delegate = delegate
      Event.push(io, self, Event::READ_EVENT)
    end

    def on_read(io)
      begin
        loop do
          @read_buffer << io.read_nonblock(DEFAULT_BUFFER_SIZE)
        end

      rescue IO::EAGAINWaitReadable
        Log.debug("Channel read finished")

      rescue Exception => e
        # Process the last message on exception
        if @delegate != nil
          @delegate.on_recv(self, @read_buffer)
          @read_buffer = String.new # Reset buffer
        end

        Log.debug("Channel error #{io}: #{e}")
        return Event::HANDLE_FAILED
      end

      if @delegate != nil
        Log.debug("Channel handle on_recv")
        len = @delegate.on_recv(self, @read_buffer)

        if len > @read_buffer.length
          len = @read_buffer.length
        end

        @read_buffer = @read_buffer[len .. -1]
      end

      return Event::HANDLE_CONTINUED
    end

    def handle_write(len)
      task = @write_task[0]

      while len > 0
        if len < task
          @write_task[0] = task - len
        end

        len -= task
        @write_task.shift

        if @delegate != nil
          @delegate.on_send(self)
           Log.debug("Channel handle on_send")
        end
      end
    end

    def on_write(io)
      len = 0

      begin
        while @write_buffer.length > 0
          len = io.write_nonblock(@write_buffer)
          @write_buffer = @write_buffer[len .. -1]
        end

        Log.debug("Channel write finished")

      rescue IO::EAGAINWaitWritable
        self.handle_write(len)

        Log.debug("Channel write continue")
        return Event::HANDLE_CONTINUED

      rescue
        Log.debug("Channel close #{io}")
        return Event::HANDLE_FAILED
      end

      self.handle_write(len)

      return Event::HANDLE_FINISHED
    end

    def on_detach(io)
      begin
        io.close

        if @delegate
          @delegate.on_close(self)
        end

      rescue
        Log.debug("Channel is already closed")
      end

      Log.debug("Channel close ok")
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
      @write_task << data.length

      Event.modify(@io, self, (Event::READ_EVENT | Event::WRITE_EVENT))

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
