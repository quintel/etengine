module Gql::Runtime
  module Functions
    module Helper

      # OBSERVE_SET is mainly used to observe the graph calculation.
      # It may be extended for more use. Observing update statements is done
      # using Update#update_element_with in the debug runtime.
      def OBSERVE_SET(objects, arguments)
        keys = arguments # OBSERVE(..., :demand)
        if arguments.is_a?(Hash) # OBSERVE(..., keys: [:demand, :share], include: [:links])
          keys     = arguments[:keys]
          includes = [arguments[:include]].flatten

          if includes.include?(:links)
            objects += flatten_uniq(objects).map{|o| [o.input_links, o.output_links]}
          end
        end
        keys ||= [:demand, :value]

        flatten_uniq(objects).each do |obj|
          obj.dataset_observe_set keys
        end
      end

      def OBSERVE_GET(objects, arguments = {})
        keys = arguments # OBSERVE(..., :demand)
        if arguments.is_a?(Hash) # OBSERVE(..., keys: [:demand, :share], include: [:links])
          keys     = arguments[:keys]
          includes = [arguments[:include]].flatten

          if includes.include?(:links)
            objects += flatten_uniq(objects).map{|o| [o.input_links, o.output_links]}
          end
        end
        keys ||= [:demand, :value]

        flatten_uniq(objects).each do |obj|
          obj.query.dataset_observe_get(keys) if obj.respond_to? :query
          obj.dataset_observe_get keys
        end
      end

      # SORT_BY( nodes , attribute_1)
      #
      def SORT_BY(*objects, arguments)
        flatten_uniq(objects).sort_by{|o| o.query(arguments) || -1.0}
      end


      # TXT_TABLE( nodes ; attribute_1 ; attribute_2 ; ... )
      #
      # TXT_TABLE(
      #   SORT_BY(V(G(electricity_production));merit_order_end);
      #   key; merit_order_start; merit_order_end; full_load_hours
      # )
      #
      def TXT_TABLE(objects, *arguments)
        DebugTable.new(objects, arguments, :txt)
      end

      # TXT_TABLE( nodes ; attribute_1 ; attribute_2 ; ... )
      #
      # TXT_TABLE(
      #   SORT_BY(V(G(electricity_production));merit_order_end);
      #   key; merit_order_start; merit_order_end; full_load_hours
      # )
      #
      def EXCEL_TABLE(objects, *arguments)
        DebugTable.new(objects, arguments, :tsv)
      end

      #######
      private
      #######

      # Returns data for use in a TXT or EXCEL table.
      #
      # The first row contains the headers (attributes) with subsequent rows
      # containing the result of each requested GQL expression.
      #
      def table_data(objects, *arguments)
        rows = [[*arguments]]

        rows += flatten_uniq(objects).map do |obj|
          arguments.map do |argument|
            begin
              obj = obj.query if obj.respond_to?(:query)
              if argument.respond_to?(:call)
                obj.instance_eval(&argument)
              else
                obj.instance_eval(argument.to_s)
              end
            rescue => e
              'error'
            end
          end
        end

        rows
      end

    end
  end
end
