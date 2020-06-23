module Qernel
  class Edge
    extend ActiveModel::Naming

    # Public: Defines a method on the Edge which, when called, will call the
    # method of the same name on the parent node's NodeApi, reducing
    # the value according to the slot conversion and parent share.
    #
    # Returns nothing.
    def self.delegated_calculation(name, lossless = false)
      define_method(name) do |*args|
        delegated_calculation(name, lossless, *args)
      end
    end

    # Dataset ------------------------------------------------------------------

    include DatasetAttributes

    dataset_accessors :co2_per_mj, :calculated, :country_specific,
                      :share, :value

    def self.dataset_group; :graph; end

    delegated_calculation :primary_demand, true
    delegated_calculation :primary_demand_of, true
    delegated_calculation :primary_demand_of_carrier, true
    delegated_calculation :sustainability_share
    delegated_calculation :dependent_supply_of_carrier, true

    # Accessors ----------------------------------------------------------------

    # The graph object of the current request. Used by DatasetAttributes to read
    # the dataset.
    attr_accessor :graph

    attr_reader :lft_node, :rgt_node, :carrier,
      :id, :key, :edge_type, :groups

    # Flow ---------------------------------------------------------------------

    alias_method :demand, :value

    # --------------------------------------------------------------------------

    # Creates a new Edge. Automatically adds the connection to the parent and
    # child nodes.
    #
    # id       - A unique identifier for the edge. A non-integer value will be
    #            run through the Hashpipe library which returns an integer hash
    #            of the ID for fast lookups and comparison.
    # lft      - The left, "child", node.
    # rft      - The right, "parent", node.
    # carrier  - The Carrier determining the type of energy which flows through
    #            this edge.
    # type     - A symbol which tells the edge how it should be calculated. See
    #            the options in Calculation::Edges.for.
    # reversed - Should the edge input and output be swapped when calculating?
    # groups   - An array of groups to which the edge belongs.
    #
    # Returns a edge.
    def initialize(id, lft, rgt, carrier, type, reversed = false, groups = [])
      @key = id
      @id  = id.is_a?(Numeric) ? id : Hashpipe.hash(id)

      @reversed      = reversed
      @lft_node = lft
      @rgt_node = rgt
      @carrier       = carrier
      @groups        = groups.freeze
      @edge_type     = type.to_sym

      lft_node.add_input_edge(self)
      rgt_node.add_output_edge(self)

      self.dataset_key # memoize dataset_key
    end

    # Enables edge.electricity?, edge.network_gas?, etc.
    Etsource::Dataset::Import.new('nl').carrier_keys.each do |carrier_key|
      delegate :"#{ carrier_key }?", to: :carrier
    end

    # Public: The query object used by some GQL functions.
    #
    # Returns self.
    def query
      self
    end

    # Public: The sector to which the edge belongs. This is the same as the sector
    # of the child (consumer, "left-hand") node.
    #
    # Returns a symbol.
    def sector
      lft_node.sector_key
    end

    def carrier_key
      carrier && carrier.key
    end

    def inspect
      "<Qernel::Edge #{key.inspect}>"
    end

    alias_method :to_s, :inspect

    # Edge Types ---------------------------------------------------------------

    def share?
      @edge_type === :share
    end

    def flexible?
      @edge_type === :flexible
    end

    def dependent?
      @edge_type === :dependent
    end

    def constant?
      @edge_type === :constant
    end

    def inversed_flexible?
      @edge_type === :inversed_flexible
    end

    def reversed?
      @reversed
    end

    def energetic?
      ! lft_node.non_energetic_use?
    end

    # Calculation --------------------------------------------------------------

    def max_demand
      dataset_get(:max_demand) || rgt_node.query.max_demand
    end

    def priority
      dataset_get(:priority) || -Float::INFINITY
    end

    # Public: The share of energy from the parent node carried away by this
    # edge.
    #
    # This is only able to return a meaningful value AFTER the graph has been
    # calculated, since prior to this the edge or node may not yet have a
    # demand.
    #
    # Returns a Numeric, or nil if no share can be calculated.
    def parent_share
      @parent_share ||=
        if value && (slot_demand = rgt_output.external_value)
          slot_demand.zero? ? 0.0 : value / slot_demand
        end
    end

    # Public: Delegates a calculation to the parent node NodeApi, reducing
    # the returned value in accordance with the slot conversion and edge share.
    #
    # calculation - The method to be called on the NodeApi
    # *args       - Additional arguments to be passed to the calculation method.
    #
    # Returns a number, or nil if the calculation returned nil.
    def delegated_calculation(calculation, lossless = false, *args)
      value = rgt_node.query.send(calculation, *args)

      if value
        loss_comp = lossless ? rgt_node.loss_compensation_factor : 1.0
        value * (output.conversion * loss_comp) * parent_share
      end
    end

    # Calculation --------------------------------------------------------------

    def calculate
      unless self.calculated
        self.value      = Calculation::Edges.for(self).call(self)
        self.calculated = true
      end

      self.value
    end

    # Updates the shares according to demand. This is needed so that
    # recursive_factors work correctly.
    def update_share
      slot_demand = (lft_input && lft_input.expected_external_value) || 0.0

      if self.value and slot_demand and slot_demand > 0
        self.share = self.value / slot_demand
      elsif value == 0.0
        siblings_and_self = lft_input.edges

        # if the value is 0.0, we have to set rules what edges
        # get what shares. In order to have recursive_factors work properly.
        # To fix https://github.com/dennisschoenmakers/etengine/issues/178
        # we have to change the following line:
        if flexible?
          other_share =
            siblings_and_self.sum do |edge|
              edge.share.nil? || edge == self ? 0.0 : edge.share.to_f
            end

          # Disallow a negative energy flow.
          self.share = other_share > 1 ? 0.0 : 1.0 - other_share
        elsif !share?
          self.share = siblings_and_self.one? ? 1.0 : 0.0
        end
      end
    end

    # Demands ------------------------------------------------------------------

    # The slot to which the energy for this edge flows, irrespective of the
    # edges "reversed" setting.
    #
    # Returns a Qernel::Slot.
    def lft_input
      lft_node.input(@carrier)
    end

    # The slot from where the energy for this edge comes, irrespective of the
    # edge's "reversed" setting.
    #
    # Returns a Qernel::Slot.
    def rgt_output
      rgt_node.output(@carrier)
    end

    # The slot from where the energy for this edge comes, for calculation
    # purposes. If the edge is reversed it will instead return the slot which
    # receives the edge energy.
    #
    # Returns a Qernel::Slot.
    def input
      reversed? ? rgt_output : lft_input
    end

    # The slot that receives the energy of this edge. If reversed it will be the
    # lft node.

    # The slot which receives energy from this edge, for calculation purposes.
    # If the edge is reversed it will instead return the slot from which the
    # energy comes.
    #
    # Returns a Qernel::Slot.
    def output
      reversed? ? lft_input : rgt_output
    end

    # Queries ------------------------------------------------------------------

    # Public: Returns how much CO2 is emitted per MJ passing through the edge.
    #
    # Delegates to the carrier if no custom edge value is set. Note that setting
    # a custom `co2_per_mj` only has an effect if the edge would be used to
    # calculate CO2 emissions.
    #
    # See Qernel::RecursiveFactor::PrimaryCo#co2_per_mj_factor
    #
    # Returns a numeric.
    def co2_per_mj
      fetch(:co2_per_mj) { @carrier.co2_per_mj }
    end

    private

    # Internal: Micro-optimization which improves the performance of
    # Array#flatten when the array contains Edges.
    #
    # See http://tenderlovemaking.com/2011/06/28/ ...
    #       til-its-ok-to-return-nil-from-to_ary
    def to_ary
      nil
    end
  end # Edge
end # Qernel
