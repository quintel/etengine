module Qernel
  class Edge
    extend ActiveModel::Naming
    include DatasetAttributes

    # Dataset ------------------------------------------------------------------

    DATASET_ATTRIBUTES = %i[calculated country_specific share value].freeze
    dataset_accessors DATASET_ATTRIBUTES

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

    def graph_name
      @lft_node.graph_name
    end

    def dataset_group
      @dataset_group ||= @lft_node.dataset_group
    end

    # Enables edge.electricity?, edge.network_gas?, etc.
    Etsource::Dataset::Import.new('nl').carrier_keys.each do |carrier_key|
      delegate :"#{carrier_key}?", to: :carrier
    end

    # Public: The query object used by some GQL functions.
    #
    # Returns self.
    def query
      @query ||= EdgeApi.from_edge(self)
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
      "#<Qernel::Edge #{key.inspect}>"
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

    # Public: The share of the parent node energy carried away by this edge.
    #
    # This can always return a value when the edge is reversed and has a value for its "share"
    # attribute (is a type=share edge). Otherwise, a value can only be returned AFTER the graph has
    # been calculated since, prior to this, the edge or node may not yet have a demand.
    #
    # Returns a Numeric, or nil if no share can be calculated.
    def parent_share
      fetch(:parent_share) do
        if reversed? && share
          share
        elsif demand && (slot_demand = rgt_output.external_value)
          slot_demand.zero? ? 0.0 : demand / slot_demand
        end
      end
    end

    # Public: The share of the child node energy provided by this edge.
    #
    # This can always return a value when the edge is reversed and has a value for its "share"
    # attribute (is a type=share edge). Otherwise, a value can only be returned AFTER the graph has
    # been calculated since, prior to this, the edge or node may not yet have a demand.
    #
    # Returns a Numeric, or nil if no share can be calculated.
    def child_share
      fetch(:child_share) do
        if !reversed? && share
          share
        elsif demand && (slot_demand = lft_input.external_value)
          slot_demand.zero? ? 0.0 : demand / slot_demand
        end
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
      share_source = reversed? ? rgt_output : lft_input
      slot_demand = share_source&.expected_external_value || 0.0

      if demand && slot_demand&.positive?
        self.share = value / slot_demand
      elsif demand == 0.0
        siblings_and_self = share_source.edges

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

    private

    # Internal: Micro-optimization which improves the performance of
    # Array#flatten when the array contains Edges.
    #
    # See http://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
    def to_ary
      nil
    end
  end # Edge
end # Qernel
