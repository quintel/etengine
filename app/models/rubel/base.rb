module Rubel
  class ErrorReporter
    def initialize(error, string)
      raise string + " " + error.message
    end
  end

  class Base < BasicObject
    include ::Rubel::Functions::Aggregate
    include ::Rubel::Functions::Lookup
    include ::Rubel::Functions::Legacy
    include ::Rubel::Functions::Core

    attr_reader :scope

    def initialize(scope = nil)
      @scope = scope
    end

    def query(string = nil)
      sanitize!(string)
      
      if string.is_a?(::String)
        instance_eval(string)
      else
        instance_exec(&string)
      end
      
    rescue => e
      ErrorReporter.new(e, string)
    end

    def sanitize!(string)
      string.gsub!('::', '')
    end

    # Same as method_missing but for constants, like class names.
    def self.const_missing(name)
      name
    end

    # returns name as Symbol if args are empty
    # if args are present, return a Proc
    def method_missing(name, *args)
      if args.present?
        ::Proc.new { self.send(name, *args)}
      else
        name.to_sym
      end
    end
  end
end