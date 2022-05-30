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

        if factor.to_s.start_with?('carrier:')
          attribute = factor[8..].strip

          return slot.carrier.public_send(attribute) if slot.carrier.respond_to?(attribute)

          raise "Invalid molecule conversion attribute for #{slot.carrier.key} carrier " \
                "on #{slot.node.key} node: #{factor.inspect}"
        elsif factor.to_s.start_with?('edges:')
          attribute = factor[6..].strip
          total = slot.edges.sum(&:demand)

          return 0.0 if total.zero?

          return slot.edges.sum do |edge|
            edge.query.public_send(attribute) * (edge.demand / total)
          end
        end

        factor
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
    end
  end
end
