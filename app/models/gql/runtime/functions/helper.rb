module Gql::Runtime
  module Functions
    module Helper

      def OBSERVE_SET(*objects, arguments)
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

      def OBSERVE_GET(*objects, arguments)
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

      # SORT_BY( converters , attribute_1)
      #
      def SORT_BY(*objects, arguments)
        flatten_uniq(objects).sort_by{|o| o.query(arguments) || -1.0}
      end


      # TXT_TABLE( converters ; attribute_1 ; attribute_2 ; ... )
      #
      # TXT_TABLE(
      #   SORT_BY(V(G(electricity_production));merit_order_end);
      #   key; merit_order_start; merit_order_end; full_load_hours
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