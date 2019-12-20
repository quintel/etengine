# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Helper class for determining curves for the demand for electricity due
    # to heating in households on graphs which do not use the full Merit/Fever
    # plugins.
    class SimpleHouseholdHeat
      def initialize(graph, curve_set)
        @graph = graph
        @curve_set = curve_set
        @fever_curves = Qernel::FeverFacade::Curves.new(@graph)
      end

      # Public: Returns the total amount of demand for the Fever group matching
      # the given +group_name+.
      #
      # Returns a numeric.
      def demand_value(group_name)
        group_producers(group_name).sum do |producer|
          # We use demand * conversion because output_of_electricity requires a
          # calculated graph, which is not always the case when computing
          # time-resolved loads.
          producer.demand * producer.converter_api.electricity_input_conversion
        end
      end

      def curve(group_name)
        electricity_demand = demand_value(group_name)

        consumers = group_consumers(group_name)
        total_demand = consumers.sum(&:demand)

        # Prevent curve consisting of NaN,NaN,... when total demand is zero.
        if total_demand.zero?
          return Causality::AggregateCurve.zeroed_profile
        end

        # Get demand curves for each consumer.
        individual =
          consumers.map do |consumer|
            @fever_curves.curve(consumer.fever.curve, consumer) *
              (electricity_demand * (consumer.demand / total_demand))
          end

        Merit::CurveTools.add_curves(individual)
      end

      private

      def group_consumers(group_name)
        group_converters_of_type(group_name, :consumer)
      end

      def group_producers(group_name)
        group_converters_of_type(group_name, :producer)
      end

      def group_converters_of_type(group_name, type)
        Etsource::Fever.group(group_name).keys(type).map do |key|
          @graph.converter(key)
        end
      end
    end
  end
end
