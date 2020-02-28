# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Converts a Qernel::Converter to a Reconciliation adapter and back again.
    class Adapter
      def self.adapter_for(converter, context)
        type = context.node_config(converter).type

        klass =
          case type
          when :consumer
            ConsumerAdapter.factory(converter, context)
          when :export
            ExportAdapter
          when :producer
            ProducerAdapter.factory(converter, context)
          when :import
            ImportAdapter
          when :storage
            StorageAdapter
          else
            raise 'Unknown reconciliation participant type for ' \
                  "#{converter.key}: #{type.inspect}"
          end

        klass.new(converter, context)
      end

      def initialize(converter, context)
        @converter = converter
        @context   = context
        @config    = context.node_config(converter)
      end

      def setup(phase:)
        @carrier_demand = calculate_carrier_demand if phase == demand_phase
      end

      def carrier_demand
        @carrier_demand ||
          raise("carrier_demand not yet calulated for #{@converter.key}")
      end

      def demand_curve
        @demand_curve ||= demand_profile * carrier_demand
      end

      def inspect
        "#<#{self.class.name} #{@converter.key.inspect}>"
      end

      # Public: Receives the reconciliation calculator and makes changes to the
      # graph according to the behaviour of the adapter in the calculation.
      #
      # Override in subclasses as needed.
      #
      # Returns nothing.
      def inject!(_calculator); end

      private

      def calculate_carrier_demand
        raise NotImplementedError
      end

      # Internal: Defines when in the time_resolve calculation to create the
      # demand curve.
      #
      # Most participants in Reconciliation have static curves which are a
      # function of a load profile and the demand of the converter. The demand
      # curve of these participants must be created before Merit detaches the
      # dataset, afterwhich the converter demand will be zero (pending
      # recalculation). These are :static.
      #
      # Others only have a correct demand curve _after_ the Merit calculation,
      # such as power-to-gas. These are :dynamic.
      #
      # Returns a Symbol.
      def demand_phase
        @config.profile.to_s.strip.start_with?('self') ? :dynamic : :static
      end

      # Internal: Creates the profile describing the shape of the converter
      # demand throughout the year.
      #
      # Returns a Merit::Curve.
      def demand_profile
        @context.curves.curve(@config.profile, @converter)
      end

      # Internal: Fetches demand from the converter.
      def converter_demand
        if @converter.demand.nil? && @converter.query.number_of_units.zero?
          # Demand may be nil if it is set by Fever, and the producer has no
          # installed units (therefore was omitted from the calculation).
          0.0
        else
          @converter.demand
        end
      end

      # Internal: The full load hours of the participant.
      #
      # Returns a numeric.
      def full_load_hours
        @converter.converter_api.full_load_hours
      end
    end
  end
end
