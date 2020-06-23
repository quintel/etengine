module Qernel::Calculation
  module Edges
    # Returns an object which responds to #call, capable of calculating a demand
    # for the given +edge+.
    def self.for(edge)
      case edge.edge_type
      when :constant          then Constant
      when :share             then Share
      when :dependent         then Dependent
      when :inversed_flexible then InversedFlexible
      when :flexible          then Flexible
      end
    end

    # Public: Determines if the given +edge+ will have its value calculated by
    # looking at the parent (output) node.
    #
    # Returns true or false.
    def self.calculated_by_parent?(edge)
      edge.reversed? ||
        edge.dependent? ||
        edge.inversed_flexible? ||
        (edge.constant? && edge.share.nil?)
    end

    # Public: Determines if the given +edge+ will have its value calculated by
    # looking at the child (input) node.
    #
    # Returns true or false.
    def self.calculated_by_child?(edge)
      ! calculated_by_parent?(edge)
    end

    # Calculates the demand of a constant edge. In many cases these are
    # identical to dependent edges, except they they will (ab)use the "share"
    # attribute, if a value is set, to set the demand.
    Constant = lambda do |edge|
      if edge.share.nil?
        # When no share is defined in the data (from ETSource/Refinery), the
        # edge is expected to take the full amount of energy from the output
        # slot.
        Dependent.call(edge) ||
          raise("Constant edge with share = nil expects a demand of parent " \
                "node #{ edge.rgt_node }")
      else
        # When a share value is present in the data, it isn't actually a share
        # but an absolute amount of energy to be assigned to the edge as demand.
        edge.share
      end
    end

    # Dependent edges carry away 100% of the energy from the parent (output)
    # slot.
    Dependent = lambda do |edge|
      edge.output.expected_value
    end

    # Calculates the demand of a share edge. Share edges expect the demand of
    # the child slot to be known, and has a "share" attribute which detmines
    # what share of this energy is provided by the edge.
    #
    # A slot with 200 demand -- and a share edge with a share of 0.25 -- will
    # expect the edge to carry 50.
    Share = lambda do |edge|
      if edge.share.nil?
        raise "Share is nil for the share edge: #{ edge }"
      elsif edge.input.expected_value.nil?
        raise "external_demand is nil for the slot: #{ edge.input }"
      else
        edge.share * edge.input.expected_value
      end
    end

    # Calculates the demand of an inversed flexible edge. Like a flexible, this
    # looks at how much excess energy the parent (output) slot has, and assigns
    # that amount to be taken away by the inversed flexible.
    InversedFlexible = lambda do |edge|
      output = edge.rgt_node.demand * edge.output.conversion
      excess = output - edge.output.external_edge_value

      (excess < 0.0) ? 0.0 : excess
    end

    # Calculates the demand of a flexible edge. Flexible edges determine how
    # much demand is unfulfilled on the child (input) slot, and assigns this
    # amount to come through the flexible.
    module Flexible
      # Calculates the given +edge+.
      def self.call(edge)
        if required = edge.input.expected_value
          supplied = (edge.input && edge.input.external_value) || 0.0
          deficit  = required - supplied

          apply_boundaries(edge, deficit)
        end
      end

      #######
      private
      #######

      # Internal: Ensures that a given demand +amount+ does not exceed the
      # maximum demand permitted for the edge, and is not less than the minimum
      # demand.
      #
      # Returns a Numeric.
      def self.apply_boundaries(edge, amount)
        minimum = min_demand(edge)
        maximum = edge.max_demand

        if minimum.present? && amount < minimum
          minimum
        elsif maximum.present? && amount > maximum
          maximum
        else
          amount
        end
      end

      # Internal: Determines the minimum acceptable demand for the edge.
      #
      # Returns a Numeric, or nil if there is no minimum demand.
      def self.min_demand(edge)
        if ! edge.carrier.electricity? &&
              ! edge.rgt_node.energy_import_export?
          0.0
        elsif edge.lft_node.has_loop?
          # Typically a loop contains an inversed flexible (to the left) and a
          # flexible (to the right), to the same node. Sometimes this
          # construct does not work properly, so we manually make sure a
          # flexible cannot go below 0.0.
          #
          # If you remove this you will encounter stack overflow problems when
          # calculating primary demand if both edges have values other than 0.0
          # because of the == check in recursive_factor. Forcing 0.0 on the
          # flexible edge closes the loop.
          0.0
        else
          nil
        end
      end
    end # Flexible
  end # Edges
end # Qernel::Calculation
