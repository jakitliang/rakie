module Rakie
  class ParseStatus
    ERROR = -1
    CONTINUE = 0
    PENDING = 1
    COMPLETE = 2
  end

  module Proto
    PARSE_BEGIN = 0

    # @return [Integer]
    def parse_status
      @parse_status ||= ParseStatus::CONTINUE
    end

    # @return [Integer]
    def parse_state
      @parse_state ||= PARSE_BEGIN
    end

    # @param [Integer] state
    def parse_state=(state)
      @parse_state = state
      # puts("Set state: #{@parse_state}")
    end

    # @return [Integer]
    def parse_offset
      @parse_offset ||= 0
    end

    # @param [Integer] offset
    def parse_offset=(offset)
      @parse_offset = offset
    end

    # @param [String] source
    def parse(source)
      status = ParseStatus::CONTINUE
      
      while status == ParseStatus::CONTINUE
        status = self.deserialize(source)
      end

      if status == ParseStatus::PENDING
        status = ParseStatus::CONTINUE
      end

      offset = @parse_offset
      @parse_status = status
      @parse_offset = 0

      return offset
    end

    # @param [Object] object
    # @return [String]
    def to_s
      self.serialize
    end
  end
end