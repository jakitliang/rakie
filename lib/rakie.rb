
module Rakie
  NAME = "rakie"
  VERSION = [0, 1, 0]
  MODE_DEV = 0
  MODE_REL = 1

  def self.current_mode
    @current_mode ||= MODE_DEV
  end

  def self.version_s
    VERSION.join('.')
  end

  def self.full_version_s
    "#{NAME} v#{self.version_s}"
  end
end

require "rakie/channel"
require "rakie/event"
require "rakie/proto"
require "rakie/http_proto"
require "rakie/websocket_proto"
require "rakie/simple_server"
require "rakie/web_server"
require "rakie/websocket_server"
require "rakie/tcp_channel"
require "rakie/tcp_server_channel"
require "rakie/log"
