module Gql
  module QueryInterface::Base
    def input_value
      @input_value
    end

    def input_value=(val)
      @input_value = val
    end

    def query(obj, input_value = nil)
      if obj.is_a?(Gquery)
        subquery(obj.key)
      elsif obj.is_a?(Input)
        execute_input(obj, input_value)
      elsif obj.is_a?(String)
        @rubel.query(Gquery.gql3_proc(obj))
      else
        raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{obj.inspect}.")
      end
    end

    # A subquery is a call to another query.
    # e.g. "SUM(QUERY(foo))"
    #
    def subquery(gquery_key)
      if gquery = get_gquery(gquery_key)
        ActiveSupport::Notifications.instrument("gql.query.subquery: #{gquery_key}") do
          @rubel.query(gquery.gql3)
        end
      else
        nil
      end
    end
    
    def execute_input(input, value = nil)
      self.input_value = value.to_s
      self.input_value = "#{self.input_value}#{input.v1_legacy_unit}" unless self.input_value.include?('%')  
      @rubel.query(Gquery.gql3_proc(input.query))
    rescue => e
      raise Gql::GqlError.new("UPDATE: #{input.key}:\n #{e.inspect}")
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
