module Rubel
  class ErrorReporter
    def initialize(error, string)
      raise string + error.message
    end
  end

  class Base# < BasicObject
    include ::Rubel::Functions::Aggregate
    include ::Rubel::Functions::Lookup
    include ::Rubel::Functions::Legacy

    attr_reader :counter

    def initialize(scope = nil)
      @counter = 0
      @scope = scope
    end

    def scope; @scope; end

    def query(string = nil)
      # sanitize!(string)
      # convert_legacy!(string)
      
      if string.is_a?(String)
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

    def convert_legacy!(string)
      string.gsub!("\n", '')
      string.gsub!(/;([^\)]*)\)/, ';"\1")')
      string.gsub!("[", "(")
      string.gsub!("]", ")")
      string.gsub!(';', ',')
      string.gsub!("\s", '')
      string.gsub!("\t", '')
    end

    def exec(proc = nil, &block)
      if proc
        self.instance_exec(&proc)
      else
        self.instance_exec(&block)
      end
    end

    # V(foo) => LOOKUP(foo)
    # V(foo, bar) => if bar is converter: LOOKUP(foo, bar) 
    # V(foo, bar) => if bar is not converter: ATTR(LOOKUP(foo), bar) 
    # V(foo, bar, baz) => if baz is not converter: ATTR(LOOKUP(foo, bar), baz)
    def V(*args)
      last_key = LOOKUP(args.last)
      last_key.flatten!
      
      if args.length == 1
        last_key
      elsif last_key.length > 0
        LOOKUP(*args)
      else
        attr_name = args.pop
        ATTR(LOOKUP(*args), attr_name)
      end
    end
    alias VALUE V

    def QUERY(key)
      scope.subquery(key.to_s)
    end
    alias Q QUERY

    # returns empty array instead of nil when nothing found  
    def LOOKUP(*keys)
      keys.flatten!
      keys.map! do |key| 
        if key.respond_to?(:to_sym)
          @scope.converters(key)
        else
          key
        end
      end
      keys
    end

    def IF(condition, true_stmt, false_stmt)
      if condition
        true_stmt.respond_to?(:call) ? true_stmt.call : true_stmt
      else
        false_stmt.respond_to?(:call) ? false_stmt.call : false_stmt
      end
    end

    def ATTR(args, attr_name)
      args.flatten!
      args.map! do |a| 
        a = a.respond_to?(:query) ? a.query : a
        a.instance_eval(attr_name)
        # if attr_name.respond_to?(:call)
        #   a.instance_exec(&attr_name)
        # elsif attr_name.is_a?(::String)
        #   a.instance_eval(attr_name)
        # else
        #   a.send(attr_name)
        # end
      end
      args
    end

    def self.const_missing(name)
      name
    end

    def method_missing(name, *args)
      @counter += 1
      name.to_sym
    end
  end
end