module Gql::Grammar
  module Functions
    module Helper

      # SORT_BY( converters , attribute_1)
      #
      def SORT_BY(*objects, arguments)
        flatten_uniq(objects).sort_by{|o| o.query(arguments) || -1.0}
      end


      # TXT_TABLE( converters ; attribute_1 ; attribute_2 ; ... )
      #
      # TXT_TABLE(
      #   SORT_BY(V(G(electricity_production));merit_order_end); 
      #   full_key; merit_order_start; merit_order_end; full_load_hours
      # )
      #
      def TXT_TABLE(objects, *arguments)
        rows = [arguments]
        rows += flatten_uniq(objects).map do |obj| 
          arguments.map{|a| obj.query.instance_eval(a.to_s) } 
        end
        rows.to_table(:first_row_is_head => true).to_s
      end
    end
  end
end