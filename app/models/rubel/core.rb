module Rubel
  module Core

    # @param [Object] scope The object through which GQL functions can access your application data.
    def initialize(scope = nil)
      @scope = scope
    end

    # The object through which GQL functions can access your application data.
    def scope; @scope; end

    # make -> and lambda work
    def lambda(&block)
      ::Kernel.lambda(&block)
    end

    # query - The String or Proc to be executed
    def query(query = nil, raw = nil)
      if query.is_a?(::String)
        sanitize!(query)
        instance_eval(query)
      else
        instance_exec(&query)
      end
      
    rescue => e
      ErrorReporter.new(e, query)
    end

    # Protect from Ruby injection.
    def sanitize!(string)
      string.gsub!('::', '')
    end

    def self.const_missing(name)
      name
    end

    # Returns method name as a Symbol if args are empty 
    # or a Proc calling method_name with (evaluated) args [1].
    def method_missing(name, *args)
      if args.present?
        ::Proc.new { self.send(name, *args)  }
      else
        name.to_sym
      end
    end
  end
end