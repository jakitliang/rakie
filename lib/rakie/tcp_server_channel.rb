module Rakie
  class TCPServerChannel < TCPChannel
    # @param host [String]
    # @param port [Integer]
    # @param delegate [Object]
    # @overload initialize(host, port, delegate)
    # @overload initialize(host, port)
    # @overload initialize(port)
    def initialize(host=LOCAL_HOST, port=3001, delegate=nil)
      socket = nil
      
      if port == nil
        port = host
        host = LOCAL_HOST
      end
      
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
      socket.bind(Socket.pack_sockaddr_in(port, host))
      socket.listen(255)

      @clients = []

      super(host, port, delegate, socket)
    end

    # @param io [Socket]
    def on_read(io)
      begin
        ret = io.accept_nonblock
        # @type client_io [Socket]
        client_io = ret[0]
        # @type client_info [Addrinfo]
        client_info = ret[1]
        client_name_info = client_info.getnameinfo
        client_host = client_name_info[0]
        client_port = client_name_info[1]
        channel = TCPChannel.new(client_host, client_port, nil, client_io)

        if @delegate != nil
          Log.debug("TCPServerChannel has delegate")
          @delegate.on_accept(channel)

        else
          Log.debug("TCPServerChannel no delegate")
          @clients << channel
        end

        Log.debug("TCPServerChannel accept #{channel}")

      rescue IO::EAGAINWaitReadable
        Log.debug("TCPServerChannel accept wait")

      rescue
        Log.debug("TCPServerChannel Accept failed #{io}")
        return Event::HANDLE_FAILED
      end

      return Event::HANDLE_CONTINUED
    end

    def accept
      @clients.shift
    end
  end
end

require "socket"