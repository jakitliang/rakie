
module Rakie
  NAME = "rakie"
  MODE_DEV = 0
  MODE_REL = 1

  def self.current_mode
    @current_mode ||= MODE_REL
  end
end

require "rakie/channel"
require "rakie/event"
require "rakie/proto"
require "rakie/http_proto"
require "rakie/websocket_proto"
require "rakie/simple_server"
require "rakie/http_server"
require "rakie/websocket"
require "rakie/websocket_server"
require "rakie/tcp_channel"
require "rakie/tcp_server_channel"
require "rakie/log"
require "rakie/version"
