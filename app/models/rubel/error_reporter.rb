module Rubel
  class ErrorReporter
    def initialize(error, string)
      raise "error: #{error.message}\n#{error.backtrace[0..5]*"\n"}"
    end
  end
end