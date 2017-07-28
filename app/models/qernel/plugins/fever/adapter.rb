module Qernel::Plugins
  module Fever
    # Base class which handles setting up the participant in Fever, and
    # converting data post-calculation to be added back to ETEngine.
    class Adapter
      attr_reader :converter

      def self.adapter_for(converter, graph, dataset)
        type = converter.dataset_get(:fever).type.to_sym

        klass = case type
          when :producer then ProducerAdapter.factory(converter, graph, dataset)
          when :storage  then StorageAdapter
          when :consumer then ConsumerAdapter
          else raise "Unknown Fever type: #{ type }"
        end

        klass.new(converter, graph, dataset)
      end

      def initialize(converter, graph, dataset)
        @converter = converter.converter_api
        @graph     = graph
        @dataset   = dataset
        @config    = converter.dataset_get(:fever)
      end

      def participant
        raise NotImplementedError
      end

      def inject!
        raise NotImplementedError
      end

      private

      # Internal: Fever expects totals -- not per-unit -- values. Using this
      # method will ensure you always get a total value.
      #
      # Returns a numeric.
      def total_value(attribute = nil)
        per_unit = block_given? ? yield : @converter.public_send(attribute)
        per_unit * @converter.number_of_units
      end
    end
  end # Fever
end # Qernel::Plugins
