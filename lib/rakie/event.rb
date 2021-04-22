module Rakie
  class Event
    @instance = nil

    READ_EVENT = 1
    WRITE_EVENT = 2

    HANDLE_FAILED = -1
    HANDLE_CONTINUED = 0
    HANDLE_FINISHED = 1

    def initialize
      @wait_ios = []
      @lock = Mutex.new
      @signal_in, @signal_out = IO.pipe
      @ios = {
        @signal_in => READ_EVENT
      }
      @handlers = {}
      @run_loop = Thread.new do
        self.run_loop
      end
    end
    
    def process_signal(io)
      signal = io.read(1)
      puts("Event handling #{signal}")

      if signal == 'a'
        new_io, new_handler, new_event = @wait_ios.shift
        @ios[new_io] = new_event
        @handlers[new_io] = new_handler
        puts("Event add all #{new_io} to #{new_event}")

      elsif signal == 'd'
        new_io, = @wait_ios.shift
        handler = @handlers[new_io]

        if handler != nil
          handler.on_close(new_io)
          puts("Event close #{new_io}")
        end

        @ios.delete(new_io)
        @handlers.delete(new_io)

        puts("Event remove all #{new_io}")

      elsif signal == 'm'
        new_io, new_handler, new_event = @wait_ios.shift
        @ios[new_io] = new_event
        @handlers[new_io] = new_handler
        puts("Event modify all #{new_io} to #{new_event}")

      elsif signal == 'q'
        return 1
      end

      return 0
    end

    def run_loop
      loop do
        read_ios = @ios.select {|k, v| v & READ_EVENT > 0}
        write_ios = @ios.select {|k, v| v & WRITE_EVENT > 0}

        read_ready, write_ready = IO.select(read_ios.keys, write_ios.keys, [], 5)

        if read_ready != nil
          read_ready.each do |io|
            if io == @signal_in
              @lock.lock

              if self.process_signal(io) != 0
                @lock.unlock
                return
              end

              @lock.unlock
              next
            end

            handler = @handlers[io]

            if handler == nil
              next
            end

            result = handler.on_read(io)

            if result == HANDLE_FINISHED
              @ios[io] = @ios[io] & ~READ_EVENT
              puts("Event remove read #{io}")

            elsif result == HANDLE_FAILED
              handler.on_close(io)
              puts("Event close #{io}")

              @ios.delete(io)
              @handlers.delete(io)
              puts("Event remove all #{io}")
            end
          end
        end

        if write_ready != nil
          write_ready.each do |io|
            handler = @handlers[io]

            if handler == nil
              next
            end

            result = handler.on_write(io)

            if result == HANDLE_FINISHED
              @ios[io] = @ios[io] & ~WRITE_EVENT
              puts("Event remove write #{io}")

            elsif result == HANDLE_FAILED
              handler.on_close(io)
              puts("Event close #{io}")

              @ios.delete(io)
              @handlers.delete(io)
              puts("Event remove all #{io}")
            end
          end
        end
      end
    end

    def push(io, handler, event)
      @lock.lock
      @wait_ios.push([io, handler, event])
      @signal_out.write('a')
      @lock.unlock
    end

    def delete(io)
      @lock.lock
      @wait_ios.push([io, nil, nil])
      @signal_out.write('d')
      @lock.unlock
    end

    def modify(io, handler, event)
      @lock.lock
      @wait_ios.push([io, handler, event])
      @signal_out.write('m')
      @lock.unlock
    end

    def self.instance
      @instance ||= Event.new
    end

    def self.push(io, listener, type)
      self.instance.push(io, listener, type)
    end

    def self.delete(io)
      self.instance.delete(io)
    end

    def self.modify(io, listener, type)
      self.instance.modify(io, listener, type)
    end
  end
end