module Qernel
  class QernelError < StandardError
    attr_reader :converter, :stacktrace

    def initialize(message, converter, stacktrace = nil)
      super(message)
      @converter = converter
    end
  end

  class CalculationError < StandardError
    attr_reader :converter#, :stacktrace

    def initialize(message, converter, stacktrace = nil)
      super(message)
      @converter = converter
    end

  end
end
