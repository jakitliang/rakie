module Rakie
  class Worker
    def initialize
      @thread = nil
      @mutex = Mutex.new
      @resource = ConditionVariable.new
    end
    
    
  end
end