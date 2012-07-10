module Qernel
  class Logger
    attr_accessor :nesting
    attr_reader :logs

    def initialize
      @nesting = 0
      @logs    = []
    end

    def increase_nesting
      @nesting += 1
    end

    def decrease_nesting
      @nesting -= 1
    end

    def push(attrs)
      attrs = attrs.merge(:nesting => @nesting)
      @logs.push attrs
      attrs
    end

    def log(type, key, attr_name, value = nil)
      log = push({
        key:       key,
        attr_name: attr_name, 
        value:     value, 
        type:      type
      })
      if block_given?
        increase_nesting if block_given?
        log[:value] = yield
        decrease_nesting
      end
      log[:value]
    end

    def to_hash
      logs.each_with_object({}) do |log, obj|
        obj[log[:key]] ||= {}
        obj[log[:key]].merge! log[:attr_name] => log[:value]
      end
    end
  end
end