module Qernel::Plugins
  module Merit
    # Converts a Qernel::Converter to a Merit participant and back again.
    class Adapter
      attr_reader :converter, :config

      def self.adapter_for(converter, graph, dataset)
        klass = case converter.dataset_get(:merit_order).type.to_sym
          when :dispatchable
            ProducerAdapter.factory(converter, graph, dataset)
          when :volatile, :must_run
            AlwaysOnAdapter
          when :flex
            FlexAdapter.factory(converter, graph, dataset)
          else
            self
        end

        klass.new(converter, graph, dataset)
      end

      def initialize(converter, graph, dataset)
        @converter = converter.converter_api
        @graph     = graph
        @dataset   = dataset
        @config    = converter.dataset_get(:merit_order)
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
          number_of_units:           @converter.number_of_units,
          availability:              @converter.availability,

          # The marginal costs attribute is not optional, but it is an
          # unnecessary calculation when the Merit order is not being run.
          marginal_costs:            0.0
        }
      end

      def producer_class
        fail NotImplementedError
      end
    end # Adapter
  end # Merit
end
