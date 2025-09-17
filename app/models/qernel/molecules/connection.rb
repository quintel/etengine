# frozen_string_literal: true

module Qernel
  module Molecules
    ALLOWED_ATTRIBUTES = Set.new(Atlas::NodeAttributes::GraphConnection::ALLOWED_ATTRIBUTES).freeze

    # Assists in calculating how demand can flow from one graph to another. Takes a source node (on
    # which demand is known) and an Atlas::NodeAttributes::GraphConnection to calculate the amount
    # of demand.
    class Connection
      # Public: Calculates the demand from the source node, as determined by the config.
      #
      # source - A Qernel::Node, containing a demand.
      # config - An Atlas::NodeConfig::GraphConnection with detailsfor how to calculate the demand
      #          from the source node.
      #
      # Returns a numeric.

      FACTOR_PREFIX = 'factor:'
      CARRIER_PATTERN = /\Acarrier:(.+)\z/
      EDGES_PATTERN = /\Aedges:(.+)\z/
      FACTOR_MULTIPLIER_PATTERN = /\A(.+?),\s*#{Regexp.escape(FACTOR_PREFIX)}(.+)\z/

      def self.demand(source, config)
        new(source, config).demand
      end

      def initialize(source, config)
        @source = source
        @config = config

        unless ALLOWED_ATTRIBUTES.include?(@config.attribute)
          raise "Illegal molecule conversion attribute: #{@config.attribute.inspect}"
        end
      end

      # Internal: Reads the appropriate value from the source node and calculates what should be
      # set on the molecule node.
      #
      # Conversions without a "direction" are assumed to take the demand of the source node and
      # optionally multiply it by the "conversion" attribute. Those whose direction is :input or
      # :output will specify each carrier and conversion separately.
      #
      # Returns a Numeric.
      def demand
        direction = @config.direction
        base_amount = @source.query.public_send(@config.attribute)

        if direction.nil?
          base_amount * @config.conversion_of(nil)
        else
          @config.conversion.sum do |carrier, conv_config|
            slot = conversion_slot(direction, carrier)
            factor = conversion_factor(slot)

            if factor.nil?
              raise 'Expected a numeric conversion but got nil when calculating a molecule ' \
                    "connection with #{carrier} #{conv_config.inspect} using #{@source.key}"
            end

            base_amount * slot.conversion * factor
          end
        end
      end

      def conversion_factor(slot)
        factor = @config.conversion_of(slot.carrier.key)
        return factor if factor.is_a?(Numeric)

        calculate_conversion(parse_factor(factor.to_s.strip), slot)
      end

      def conversion_slot(direction, carrier)
        case direction
        when :input  then @source.input(carrier)
        when :output then @source.output(carrier)
        else
          raise "Expected there to be a #{carrier.inspect} #{direction.inspect} slot on " \
                "#{@source.key}, but no such slot was found"
        end
      end

      private

      def parse_factor(factor_str)
        if (match = factor_str.match(FACTOR_MULTIPLIER_PATTERN))
          main_part = match[1].strip
          multiplier = match[2].strip.to_f
        else
          main_part = factor_str
          multiplier = 1.0
        end

        case main_part
        when CARRIER_PATTERN
          { type: :carrier, attribute: $1.strip, multiplier: multiplier }
        when EDGES_PATTERN
          { type: :edges, attribute: $1.strip, multiplier: multiplier }
        else
          { type: :unknown, attribute: main_part, multiplier: multiplier }
        end
      end

      def calculate_conversion(parsed_factor, slot)
        type, attribute, multiplier = parsed_factor.values_at(:type, :attribute, :multiplier)
        case type
        when :carrier
          calculate_carrier_conversion(attribute, multiplier, slot)
        when :edges
          calculate_edges_conversion(attribute, multiplier, slot)
        else
          attribute
        end
      end

      def calculate_carrier_conversion(attribute, multiplier, slot)
        unless slot.carrier.respond_to?(attribute)
          raise_conversion_error(slot, "carrier: #{attribute}")
        end

        slot.carrier.public_send(attribute) * multiplier
      end

      def calculate_edges_conversion(attribute, multiplier, slot)
        return 0.0 if slot.edges.empty?

        total_demand = slot.edges.sum(&:demand)
        return 0.0 if total_demand.zero?

        weighted_sum = slot.edges.sum do |edge|
          edge.query.public_send(attribute) * (edge.demand / total_demand)
        end

        weighted_sum * multiplier
      end

      def raise_conversion_error(slot, factor_description)
        raise "Invalid molecule conversion attribute for #{slot.carrier.key} carrier " \
              "on #{slot.node.key} node: #{factor_description.inspect}"
      end
    end
  end
end
