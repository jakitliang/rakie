module Rakie
  class Log
    attr_accessor :out, :level

    @instance = nil

    LEVEL_INFO = 0
    LEVEL_ERROR = 1
    LEVEL_DEBUG = 2

    def initialize
      @level = LEVEL_ERROR
      @out = STDOUT
    end

    def level_text(level=nil)
      unless level
        level = @level
      end

      case level
      when LEVEL_INFO
        return "INFO"

      when LEVEL_ERROR
        return "ERROR"

      when LEVEL_DEBUG
        return "DEBUG"
      end
    end

    def level_info?
      @level >= LEVEL_INFO
    end

    def level_error?
      @level >= LEVEL_ERROR
    end

    def level_debug?
      @level >= LEVEL_DEBUG
    end

    def self.instance
      @instance ||= Log.new
    end

    def self.info(message, who=nil)
      unless self.instance.level_info?
        return
      end

      if who
        message = "#{who}: #{message}"
      end

      level = self.instance.level_text(LEVEL_INFO)
      self.instance.out.write("[#{Time.now.to_s}][#{level}] #{message}\n")
    end

    def self.error(message, who=nil)
      unless self.instance.level_error?
        return
      end

      if who
        message = "#{who}: #{message}"
      end

      level = self.instance.level_text(LEVEL_ERROR)
      self.instance.out.write("[#{Time.now.to_s}][#{level}] #{message}\n")
    end

    def self.debug(message, who=nil)
      unless self.instance.level_debug?
        return
      end

      if who
        message = "#{who}: #{message}"
      end

      level = self.instance.level_text(LEVEL_DEBUG)
      self.instance.out.print("[#{Time.now.to_s}][#{level}] #{message}\n")
    end

    def self.level
      self.instance.level
    end

    def self.level=(level)
      self.instance.level = level
    end
  end
end