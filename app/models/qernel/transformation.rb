# frozen_string_literal: true

module Qernel
  # Represents a node whose slot conversions are mimicked to flatten circularities
  class Transformation
    # Input_carrier: :output_carrier
    DISALLOWED = {
      hydrogen: :hydrogen
    }.freeze

    def initialize(node)
      @node = node
    end

    def calculate
      return if @node.demand.zero?

      dirty_input, dirty_output = dirty_slots
      dirty_input_conversion = dirty_input.sum { |carrier| @node.input(carrier).conversion }
      dirty_output_conversion = dirty_output.sum { |carrier| @node.output(carrier).conversion }

      elegible_inputs = @node.inputs.select { |i| i.conversion.positive? && dirty_input.exclude?(i.carrier.key) }
      elegible_outputs = @node.outputs.select { |o| o.conversion.positive? && dirty_output.exclude?(o.carrier.key) }

      if elegible_inputs.count.positive?
        input_division = dirty_input_conversion / elegible_inputs.count

        elegible_inputs.each do |slot|
          slot.net_conversion = slot.conversion + input_division
        end
      end

      if elegible_outputs.count.positive?
        output_division = dirty_output_conversion / elegible_outputs.count

        elegible_outputs.each do |slot|
          slot.net_conversion = slot.conversion + output_division
        end
      end

      dirty_input.each do |carrier|
        @node.input(carrier).net_conversion = 0.0
      end

      # Because RF comes from the output edges, we have to set those as well
      # to make sure the previous node knows about the flattening
      dirty_output.each do |carrier|
        @node.output(carrier).net_conversion = 0.0

        @node.output(carrier).edges.each do |edge|
          edge.net_share = 0.0
          edge.net_demand = 0.0
          edge.lft_input.net_conversion = 0.0
        end
      end
    end

    def dirty_slots
      dirty_input = Set.new
      dirty_output = Set.new
      DISALLOWED.each do |input_carrier, output_carrier|
        if @node.input(input_carrier).conversion.positive? && @node.output(output_carrier).conversion.positive?
          dirty_input << input_carrier
          dirty_output << output_carrier
        end
      end

      [dirty_input, dirty_output]
    end
  end
end
