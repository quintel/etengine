module Gql
  module QueryInterface::Base
    def input_value
      @input_value
    end

    def input_value=(val)
      @input_value = val
    end

    def query(obj, input_value = nil)
      case obj
      when Gquery then subquery(obj.key)
      when Input  then execute_input(obj, input_value)
      when String then @rubel.query(Gquery.gql3_proc(obj))
      when Proc   then @rubel.query(obj)
      else
        raise ::Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{obj.inspect}.")
      end
    end

    # A subquery is a call to another query.
    # e.g. "SUM(QUERY(foo))"
    #
    def subquery(gquery_key)
      if gquery = get_gquery(gquery_key)
        #ActiveSupport::Notifications.instrument("gql.query.subquery: #{gquery.key}") do
          @rubel.query(gquery.gql3)
        #end
      else
        nil
      end
    end
    
    def execute_input(input, value = nil)
      self.input_value = value.to_s
      self.input_value = "#{self.input_value}#{input.v1_legacy_unit}" unless self.input_value.include?('%')  
      @rubel.query(input.gql3) if input.gql3
    rescue => e
      raise "UPDATE: #{input.key}:\n #{e.inspect}"
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
  end

end
