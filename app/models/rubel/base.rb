module Rubel
  class ErrorReporter
    def initialize(error, string)
      raise  "#{string.inspect}: " + error.message
    end
  end


  # Base is the runtime with builtin sandbox to make it hard to run malicious or undefined code.
  #
  # The sandbox is created by making Base a subclass from BasicObject which has two effects:
  # - BasicObject does not include Kernel (no methods like puts, system, ``, open, etc)
  # - BasicObject is outside of the standard namespace, so classes are only found with the :: prefix.
  #
  # Base overwrites method_missing and const_missing to simply return the name as a Symbol. 
  # This allows the query language to not require "", '' or : for things like lookup keys.
  # VALUE(foo, sqrt) vs VALUE("foo", "sqrt")
  # 
  class Base < BasicObject
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

    # Returns method name as a Symbol if args are empty 
    # or a Proc calling method_name with (evaluated) args [1].
    def method_missing(name, *args)
      if args.present?
        ::Proc.new { self.send(name, *args) }
      else
        name.to_sym
      end
    end
  end
end

# [1] this allows embedding GQL into attribute names, e.g.: 
#   V(foo, primary_demand_of(CARRIER(gas)))

