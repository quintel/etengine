# frozen_string_literal: true

module Gql
  module QueryInterface::Base
    def self.included(base)
      base.instance_eval <<-RUBY, __FILE__, __LINE__ + 1
        attr_reader :input_key
        attr_accessor :input_value, :update_type
      RUBY
    end

    # def input_value
    #   @input_value
    # end

    # def input_key
    #   @input_key
    # end

    # def input_value=(val)
    #   @input_value = val
    # end

    def query(obj, input_value = nil)
      case obj
      when Gquery                  then subquery(obj.key) # sending it to subquery allows for caching of gqueries
      when Input, InitializerInput then execute_input(obj, input_value)
      when Symbol                  then subquery(obj)
      when String                  then rubel_execute(Command.new(obj))
      when Command, Proc           then rubel_execute(obj)
      else
        fail GqlError.new("Cannot execute a query with #{ obj.inspect }")
      end
    end

    # Returns the results of another gquery.
    #
    # Calling it through subquery allows for caching and memoizing. This is
    # implemented inside submodules/mixins.
    #
    def subquery(gquery_key)
      gquery = get_gquery(gquery_key)

      raise "Missing gquery: #{gquery_key.inspect}" unless gquery

      rubel_execute(gquery.command)
    end

    def execute_input(input, value = nil)
      @input_key   = input.key   # used for the logger
      # self.input_value = value.to_s
      # self.input_value = "#{self.input_value}#{input.update_type}" unless self.input_value.include?('%')

      self.input_value = value
      self.update_type = input.update_type
      rubel_execute(input.command)
    ensure
      self.input_value = nil
    end

    def get_gquery(gquery_or_key)
      if gquery_or_key.is_a?(::Gquery)
        gquery_or_key
      else
        ::Gquery.get(gquery_or_key)
      end
    end

    def rubel_execute(obj)
      @rubel.execute(obj)
    rescue StandardError, SyntaxError => ex
      raise(obj.is_a?(Command) ? CommandError.new(obj, ex) : ex)
    end
  end

end
