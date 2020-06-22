module Qernel::Calculation
  module Links
    # Returns an object which responds to #call, capable of calculating a demand
    # for the given +link+.
    def self.for(link)
      case link.link_type
      when :constant          then Constant
      when :share             then Share
      when :dependent         then Dependent
      when :inversed_flexible then InversedFlexible
      when :flexible          then Flexible
      end
    end

    # Public: Determines if the given +link+ will have its value calculated by
    # looking at the parent (output) node.
    #
    # Returns true or false.
    def self.calculated_by_parent?(link)
      link.reversed? ||
        link.dependent? ||
        link.inversed_flexible? ||
        (link.constant? && link.share.nil?)
    end

    # Public: Determines if the given +link+ will have its value calculated by
    # looking at the child (input) node.
    #
    # Returns true or false.
    def self.calculated_by_child?(link)
      ! calculated_by_parent?(link)
    end

    # Calculates the demand of a constant link. In many cases these are
    # identical to dependent links, except they they will (ab)use the "share"
    # attribute, if a value is set, to set the demand.
    Constant = lambda do |link|
      if link.share.nil?
        # When no share is defined in the data (from ETSource/Refinery), the
        # link is expected to take the full amount of energy from the output
        # slot.
        Dependent.call(link) ||
          raise("Constant link with share = nil expects a demand of parent " \
                "node #{ link.rgt_node }")
      else
        # When a share value is present in the data, it isn't actually a share
        # but an absolute amount of energy to be assigned to the link as demand.
        link.share
      end
    end

    # Dependent links carry away 100% of the energy from the parent (output)
    # slot.
    Dependent = lambda do |link|
      link.output.expected_value
    end

    # Calculates the demand of a share link. Share links expect the demand of
    # the child slot to be known, and has a "share" attribute which detmines
    # what share of this energy is provided by the link.
    #
    # A slot with 200 demand -- and a share link with a share of 0.25 -- will
    # expect the link to carry 50.
    Share = lambda do |link|
      if link.share.nil?
        raise "Share is nil for the share link: #{ link }"
      elsif link.input.expected_value.nil?
        raise "external_demand is nil for the slot: #{ link.input }"
      else
        link.share * link.input.expected_value
      end
    end

    # Calculates the demand of an inversed flexible link. Like a flexible, this
    # looks at how much excess energy the parent (output) slot has, and assigns
    # that amount to be taken away by the inversed flexible.
    InversedFlexible = lambda do |link|
      output = link.rgt_node.demand * link.output.conversion
      excess = output - link.output.external_link_value

      (excess < 0.0) ? 0.0 : excess
    end

    # Calculates the demand of a flexible link. Flexible links determine how
    # much demand is unfulfilled on the child (input) slot, and assigns this
    # amount to come through the flexible.
    module Flexible
      # Calculates the given +link+.
      def self.call(link)
        if required = link.input.expected_value
          supplied = (link.input && link.input.external_value) || 0.0
          deficit  = required - supplied

          apply_boundaries(link, deficit)
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
      def self.apply_boundaries(link, amount)
        minimum = min_demand(link)
        maximum = link.max_demand

        if minimum.present? && amount < minimum
          minimum
        elsif maximum.present? && amount > maximum
          maximum
        else
          amount
        end
      end

      # Internal: Determines the minimum acceptable demand for the link.
      #
      # Returns a Numeric, or nil if there is no minimum demand.
      def self.min_demand(link)
        if ! link.carrier.electricity? &&
              ! link.rgt_node.energy_import_export?
          0.0
        elsif link.lft_node.has_loop?
          # Typically a loop contains an inversed flexible (to the left) and a
          # flexible (to the right), to the same node. Sometimes this
          # construct does not work properly, so we manually make sure a
          # flexible cannot go below 0.0.
          #
          # If you remove this you will encounter stack overflow problems when
          # calculating primary demand if both links have values other than 0.0
          # because of the == check in recursive_factor. Forcing 0.0 on the
          # flexible link closes the loop.
          0.0
        else
          nil
        end
      end
    end # Flexible
  end # Links
end # Qernel::Calculation
