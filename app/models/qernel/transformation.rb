# frozen_string_literal: true

module Qernel
  # Represents a node whose slot conversions are mimicked to flatten circularities
  class Transformation
    # input_carrier:    :output_carrier
    DISALLOWED = {
      ammonia:          %i[ammonia],
      electricity:      %i[ammonia diesel greengas hydrogen natural_gas],
      greengas:         %i[greengas],
      hydrogen:         %i[ammonia greengas natural_gas hydrogen],
      methanol:         %i[ammonia greengas hydrogen methanol natural_gas],
      natural_gas:      %i[natural_gas],
      steam_hot_water:  %i[ammonia greengas hydrogen natural_gas]
    }.freeze

    def initialize(node)
      @node = node
    end

    def calculate
      return if @node.demand.zero?

      setup_disallowed_slots

      redistribute(:input)
      redistribute(:output)

      disallowed_slots[:input].each do |slot|
        slot.net_conversion = 0.0
      end

      # Because RF comes from the output edges, we have to set those as well
      # to make sure the previous node knows about the flattening
      disallowed_slots[:output].each do |slot|
        slot.net_conversion = 0.0

        slot.edges.each do |edge|
          edge.net_share = 0.0
          edge.net_demand = 0.0
          edge.lft_input.net_conversion = 0.0
        end
      end
    end

    private

    # Redistributes the total conversion that is was supplied by the
    # disallowed carriers evenly over the allowed carriers for the given
    # direction
    def redistribute(direction)
      slots_direction = direction == :input ? :inputs : :outputs
      allowed_slots = @node.public_send(slots_direction).select do |i|
        i.conversion.positive? && disallowed_slots[direction].exclude?(i)
      end

      division = total_disallowed_conversion(direction) / allowed_slots.count
      allowed_slots.each { |slot| slot.distribute_net_conversion(division) }
    end

    def disallowed_slots
      @disallowed_slots ||= {
        input: Set.new,
        output: Set.new
      }
    end

    def total_disallowed_conversion(direction)
      disallowed_slots[direction].sum(&:conversion)
    end

    def setup_disallowed_slots
      DISALLOWED.each do |input_carrier, output_carriers|
        output_carriers.each do |output_carrier|
          if disallowed_combination?(input_carrier, output_carrier)
            disallowed_slots[:input] <<  @node.input(input_carrier)
            disallowed_slots[:output] << @node.output(output_carrier)
          end
        end
      end
    end

    def disallowed_combination?(input_carrier, output_carrier)
      @node.input(input_carrier)&.conversion&.positive? &&
        @node.output(output_carrier)&.conversion&.positive?
    end
  end
end
