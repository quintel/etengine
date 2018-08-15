# frozen_string_literal: true

module Qernel::Plugins
  module Hydrogen
    # Converts a Qernel::Converter to a Hydrogen adapter and back again.
    class Adapter
      def self.adapter_for(converter, context)
        type = converter.hydrogen.type

        klass =
          case type
          when :consumer
            ConsumerAdapter
          when :export
            ExportAdapter
          when :producer
            ProducerAdapter
          when :import
            ImportAdapter
          when :storage
            StorageAdapter
          else
            raise 'Unknown hydrogen participant type for ' \
                  "#{converter.key}: #{type.inspect}"
          end

        klass.new(converter, context)
      end

      def initialize(converter, context)
        @converter = converter
        @context   = context
        @config    = converter.hydrogen
      end

      def setup(phase:)
        if @converter.key == :energy_transport_hydrogen_compressed_trucks
          Rails.logger.info "before-#{phase}: #{@carrier_demand}"
        end

        @carrier_demand = calculate_carrier_demand if phase == demand_phase

        if @converter.key == :energy_transport_hydrogen_compressed_trucks
          Rails.logger.info "after-#{phase}: #{@carrier_demand}"
        end

        # if phase == demand_phase
        #   Rails.logger.info("Y: #{@converter.key}")
        # else
        #   Rails.logger.info("N: #{@converter.key}")
        # end
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

      # Public: Receives the hydrogen calculator and makes changes to the graph
      # according to the behaviour of the adapter in the calculation.
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
      # Most participants in hydrogen have static curves which are a function of
      # a load profile and the demand of the converter. The demand curve of
      # these participants must be created before Merit detaches the dataset,
      # afterwhich the converter demand will be zero (pending recalculation).
      # These are :static.
      #
      # Others only have a correct demand curve _after_ the Merit calculation,
      # such as power-to-gas. These are :dynamic.
      #
      # Returns a Symbol.
      def demand_phase
        @config.profile.to_s.strip.start_with?('dynamic') ? :dynamic : :static
      end

      def demand_profile
        if @config.profile.to_s.delete(' ') == 'dynamic:self'
          ::Merit::Curve.new(
            if @converter.demand.zero?
              [0.0] * 8760
            else
              # Use input of electricity since it's faster than summing the
              # curve. It also has the nice effect whereby dividing the load
              # curve (in MW) by demand (in MJ) produces a new load profile of
              # values summing to 1/3600; effectively converting hydrogen output
              # in MJ to MW.
              total =
                @converter.demand *
                @converter.input(:electricity).conversion

              @converter.query.electricity_input_curve.map do |value|
                value.abs / total
              end
            end
          )
        else
          @context.dataset.load_profile(@config.profile)
        end
      end
    end
  end
end
