require 'minitest/autorun'
require "rakie"

class RakieTest < Minitest::Test
  def test_log
    Rakie::Log.info('test message')
    Rakie::Log.error('test message')
    Rakie::Log.debug('test message')
  end
end
