# frozen_string_literal: true

module Qernel
  module NodeApi
    # Contains calculations relating to demand and supply of carriers.
    module DemandSupply
      def demand_of_fossil
        fetch(:demand_of_fossil) do
          node.input_carriers.map do |carrier|
            if carrier.sustainable && (demand = demand_of_carrier(carrier))
              demand * (1 - carrier.sustainable)
            end
          end.compact.sum
        end
      end
      alias_method :output_of_fossil, :demand_of_fossil

      def demand_of_sustainable
        fetch(:demand_of_sustainable) do
          node.input_carriers.map do |carrier|
            if carrier.sustainable && (demand = demand_of_carrier(carrier))
              demand * carrier.sustainable
            end
          end.compact.sum
        end
      end
      alias_method :output_of_sustainable, :demand_of_sustainable

      # Public; The total amount of loss input to the node.
      #
      # Returns a numeric value in MJ.
      def input_of_loss
        if node.demand
          node.demand - node.inputs.reject(&:loss?).map(&:external_value).compact.sum
        else
          0.0
        end
      end

      # Public: The total amount of loss output from the node.
      #
      # Returns a numeric value in MJ.
      def output_of_loss
        if node.demand
          node.demand - node.outputs.reject(&:loss?).map(&:external_value).compact.sum
        else
          0.0
        end
      end

      def output_of(*carriers)
        carriers.flatten.map do |carrier|
          key = carrier.respond_to?(:key) ? carrier.key : carrier
          key == :loss ? output_of_loss : output_of_carrier(key)
        end.compact.sum
      end

      def output_of_carrier(carrier)
        c = node.output(carrier)
        c&.external_value || 0.0
      end

      # Public: Helper method to get all heat outputs (useable_heat, steam_hot_water)
      #
      # Returns a numeric value in MJ.
      def output_of_heat_carriers
        fetch(:output_of_heat_carriers) do
          output_of_useable_heat + output_of_steam_hot_water
        end
      end

      # Public: The total output of heating and cooling carriers.
      #
      # Returns a numeric value in MJ.
      def output_of_heat_and_cooling_carriers
        fetch(:output_of_heat_and_cooling_carriers) do
          output_of_useable_heat + output_of_steam_hot_water + output_of_cooling
        end
      end

      # Don't use this function before checking if all fossil carriers are
      # included!
      #
      # Returns a numeric value in MJ.
      def input_of_fossil_carriers
        fetch(:input_of_fossil_carriers) do
          input_of_coal +
            input_of_crude_oil +
            input_of_natural_gas +
            input_of_diesel +
            input_of_gasoline
        end
      end

      # Public: Returns a numeric value in MJ.
      def input_of_ambient_carriers
        fetch(:input_of_ambient_carriers) do
          input_of_ambient_heat + input_of_solar_radiation + input_of_ambient_cold + input_of_wind
        end
      end

      def demand_of_carrier(carrier)
        Rails.logger.info('demand_of_* is deprecated. Use output_of_* instead')
        output_of_carrier(carrier)
      end

      def input_of(*carriers)
        carriers.flatten.map do |carrier|
          key = carrier.respond_to?(:key) ? carrier.key : carrier
          key == :loss ? input_of_loss : input_of_carrier(key)
        end.compact.sum
      end

      def input_of_carrier(carrier)
        c = node.input(carrier)
        c&.external_value || 0.0
      end

      def supply_of_carrier(carrier)
        Rails.logger.info('supply_of_* is deprecated. Use input_of_* instead')
        input_of_carrier(carrier)
      end
    end
  end
end
