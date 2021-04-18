module Rakie
  class Event
    @@instance = Event.new

    ADD_READ_EVENT = 1
    ADD_WRITE_EVENT = 2
    DELETE_READ_EVENT = 3
    DELETE_WRITE_EVENT = 4

    def initialize
      @read_event_ios = {}
      @write_event_ios = {}
      @read_event_lock = Mutex.new
      @write_event_lock = Mutex.new
      @read_ios = {}
      @write_ios = {}
    end
    
    def run_read_loop
      read_ready, = IO.select(@read_ios.keys, [], [], 5)

      if read_ready != nil
        read_ready.each do |io|
          handler = @read_ios[io]
          handler.on_read(io)
        end
      end
    end

    def run_write_loop
      _, write_ready, = IO.select([], @write_ios.keys, [], 5)

      if write_ready != nil
        write_ready.each do |io|
          handler = @write_ios[io]
          handler.on_write(io)
        end
      end
    end

    def push(ios, listener, type)
      @event_lock.lock

      ios_size = ios.size
      while ios_size > 0
        @event_ios[type].push(ios.pop)
        ios_size -= 1
      end
      
      @event_lock.unlock
    end

    def read(ios, listener)
      @@instance.push(ios, listener, ADD_READ_EVENT)
    end

    def write(ios, listener)
      @@instance.push(ios, listener, ADD_WRITE_EVENT)
    end
  end
end