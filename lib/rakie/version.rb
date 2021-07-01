module Rakie
  VERSION = [0, 0, 12]

  def self.version_s
    VERSION.join('.')
  end

  def self.full_version_s
    "#{NAME} v#{self.version_s}"
  end
end