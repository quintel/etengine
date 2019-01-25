module Qernel::Plugins
  module Merit
    # Converts a Qernel::Converter to a Merit participant and back again.
    class Adapter
      attr_reader :converter, :config

      def self.adapter_for(converter, graph, dataset)
        klass = case converter.merit_order.type.to_sym
          when :producer
            ProducerAdapter.factory(converter, graph, dataset)
          when :flex
            FlexAdapter.factory(converter, graph, dataset)
          when :consumer
            ConsumerAdapter.factory(converter, graph, dataset)
          else
            self
        end

        klass.new(converter, graph, dataset)
      end

      def initialize(converter, graph, dataset)
        @converter = converter.converter_api
        @graph     = graph
        @dataset   = dataset
        @config    = converter.merit_order
      end

      def participant
        @participant ||= producer_class.new(producer_attributes)
      end

      def inject!
        fail NotImplementedError
      end

      private

      # Internal: Given a Merit order participant +type+ and the associated
      # Converter, +conv+, from the graph, returns a hash of attributes required
      # to set up the Participant object in the Merit order.
      #
      # Returns a hash.
      def producer_attributes
        {
          key:                       @converter.key,
          number_of_units:           source_api.number_of_units,
          availability:              source_api.availability,

          # The marginal costs attribute is not optional, but it is an
          # unnecessary calculation when the Merit order is not being run.
          marginal_costs:            0.0
        }
      end

      def producer_class
        fail NotImplementedError
      end

      # Internal: The ConverterApi from which data is taken to be used by the
      # Merit participant.
      #
      # Returns a Qernel::ConverterApi.
      def target_api
        @converter
      end

      # Internal: The ConverterApi on which the results of the Merit calcualtion
      # for the node are stored.
      #
      # Returns a Qernel::ConverterApi.
      def source_api
        @source_api ||=
          if @config.delegate.present?
            @graph.converter(@config.delegate).converter_api
          else
            @converter
          end
      end
    end # Adapter
  end # Merit
end
