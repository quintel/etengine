module Rubel
  class ErrorReporter
    def initialize(error, string)
      raise string + " " + error.message
    end
  end

  class Base < BasicObject
    include ::Rubel::Functions::Legacy
    # now override with freshened up gql functions
    include ::Rubel::Functions::Lookup
    include ::Rubel::Functions::Control
    include ::Rubel::Functions::Aggregate
    include ::Rubel::Functions::Core

    # The object through which GQL functions can access your application data.
    attr_reader :scope

    def initialize(scope = nil)
      @scope = scope
    end

    # query - The String or Proc to be executed
    def query(query = nil)
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

    # Returns method name as a Symbol if args are empty or a Proc otherwise.
    def method_missing(name, *args)
      if args.present?
        ::Proc.new { self.send(name, *args) }
      else
        name.to_sym
      end
    end
  end
end