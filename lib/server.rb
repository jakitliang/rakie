require 'socket'

module Rakie
  # Server doc
  class Server
    READ_SIZE = 1024 * 1024 * 2
    WRITE_SIZE = 1024 * 1024 * 2

    def initialize(ip, port, delegate)
      @host = ip
      @port = port
      @delegate = delegate
      @socket = TCPSocket.new(ip, port)
      @clients = {}
      @buffers = {}
    end

    def handle_accept(socket)
      client_socket, client_address = nil, nil

      begin
        client_socket, client_address = @socket.accept_nonblock
        
      rescue
        return
      end

      @clients[client_socket] = client_address
    end

    def transfer_read(socket)
      begin
        while data = socket.read_nonblock(READ_SIZE)
          @clients[socket] << data
        end

        @delegate.on_read(socket, data)

      rescue EOFError
        socket.close
        @clients.delete(socket)
        @delegate.on_close(socket)
        return

      rescue IO::EAGAINWaitReadable
        return

      rescue
        @clients.delete(socket)
        @delegate.on_close(socket)
        return
      end
    end

    def handle_read(socket)
      if socket == @socket
        handle_accept(socket)
        return
      end

      self.transfer_read(socket)
    end

    def handle_write(socket)
      
    end

    def run_loop
      read_ready, write_ready, = IO.select(@socket, [], [], 5)

      if read_ready != nil
        read_ready.each do |socket|
          self.handle_read(socket)
        end
      end

      if write_ready != nil
        write_ready.each do |socket|
          self.handle_write(socket)
        end
      end
    end
  end
end
