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
        profile_name = @config.profile.to_s.delete(' ')

        if @converter.demand&.zero?
          Merit::Curve.new([0.0] * 8760)
        elsif profile_name.start_with?('self')
          Merit::Curve.new(merit_demand_profile(profile_name[5..-1].to_sym))
        elsif profile_name.start_with?('dynamic')
          Merit::Curve.new(dynamic_demand_profile(profile_name[8..-1].to_sym))
        else
          @context.dataset.load_profile(@config.profile)
        end
      end

      # Internal: Constructs a dynamic demand profile using the electricity load
      # curve from the Merit order calculation.
      #
      # Determines the input or output of electricity using the converter demand
      # and slot since it's faster than summing the curve. It also has the nice
      # effect whereby dividing the load curve (in MW) by demand (in MJ)
      # produces a new load profile of values summing to 1/3600; effectively
      # converting the carrier demand from MJ to MW.
      #
      # input_of_electricity and output_of_electricity helpers may not be used
      # here as they require the graph to have been calcualted.
      #
      # Returns an array.
      def merit_demand_profile(name)
        Causality::SelfDemandProfile.profile(@converter.converter_api, name)
      end

      # Internal: Creates a dynamic demand profile by interpolating between two
      # or more curves, or by amplifying a baseline curve.
      #
      # Returns an array.
      def dynamic_demand_profile(name)
        if name == :solar_pv
          # Temporary special-case for solar PV which should interpolate
          # between min and max curves, rather than amplifying the min curve.
          @context.graph.plugin(:merit).curves.curve(name, @converter)
        else
          Causality::Util.amplify_curve(
            @context.dataset.load_profile("#{name}_baseline"),
            full_load_hours
          )
        end
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
