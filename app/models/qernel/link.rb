module Qernel
  class Link
    extend ActiveModel::Naming

    # Dataset ------------------------------------------------------------------

    include DatasetAttributes

    dataset_accessors :share, :value, :calculated, :country_specific

    def self.dataset_group; :graph; end

    # Accessors ----------------------------------------------------------------

    # The graph object of the current request. Used by DatasetAttributes to read
    # the dataset.
    attr_accessor :graph

    attr_reader :lft_converter, :rgt_converter, :carrier,
      :id, :key, :link_type, :groups

    # Flow ---------------------------------------------------------------------

    alias_method :demand, :value

    # --------------------------------------------------------------------------

    # Creates a new Link. Automatically adds the connection to the parent and
    # child converters.
    #
    # id       - A unique identifier for the link. A non-integer value will be
    #            run through the Hashpipe library which returns an integer hash
    #            of the ID for fast lookups and comparison.
    # lft      - The left, "child", converter.
    # rft      - The right, "parent", converter.
    # carrier  - The Carrier determining the type of energy which flows through
    #            this edge.
    # type     - A symbol which tells the link how it should be calculated. See
    #            the options in Calculation::Links.for.
    # reversed - Should the link input and output be swapped when calculating?
    # groups   - An array of groups to which the link belongs.
    #
    # Returns a link.
    def initialize(id, lft, rgt, carrier, type, reversed = false, groups = [])
      @key = id
      @id  = id.is_a?(Numeric) ? id : Hashpipe.hash(id)

      @reversed      = reversed
      @lft_converter = lft
      @rgt_converter = rgt
      @carrier       = carrier
      @groups        = groups.freeze
      @link_type     = type.to_sym

      lft_converter.add_input_link(self)
      rgt_converter.add_output_link(self)

      self.dataset_key # memoize dataset_key
    end

    # Enables link.electricity?, link.network_gas?, etc.
    Etsource::Dataset::Import.new('nl').carrier_keys.each do |carrier_key|
      delegate :"#{ carrier_key }?", to: :carrier
    end

    # Public: The query object used by some GQL functions.
    #
    # Returns self.
    def query
      self
    end

    # Public: The sector to which the link belongs. This is the same as the sector
    # of the child (consumer, "left-hand") converter.
    #
    # Returns a symbol.
    def sector
      lft_converter.sector_key
    end

    def carrier_key
      carrier && carrier.key
    end

    def inspect
      "<Qernel::Link #{key.inspect}>"
    end

    # Link Types ---------------------------------------------------------------

    def share?
      @link_type === :share
    end

    def flexible?
      @link_type === :flexible
    end

    def dependent?
      @link_type === :dependent
    end

    def constant?
      @link_type === :constant
    end

    def inversed_flexible?
      @link_type === :inversed_flexible
    end

    def reversed?
      @reversed
    end

    # Calculation --------------------------------------------------------------

    def max_demand
      dataset_get(:max_demand) || rgt_converter.query.max_demand
    end

    def priority
      dataset_get(:priority) || 1_000_000
    end

    # Public: The share of energy from the parent converter carried away by this
    # link.
    #
    # This is only able to return a meaningful value AFTER the graph has been
    # calculated, since prior to this the link or converter may not yet have a
    # demand.
    #
    # Returns a Numeric, or nil if no share can be calculated.
    def parent_share
      @parent_share ||=
        if value && (slot_demand = rgt_output.external_value)
          slot_demand.zero? ? 0.0 : value / slot_demand
        end
    end

    # Calculation --------------------------------------------------------------

    def calculate
      unless self.calculated
        self.value      = Calculation::Links.for(self).call(self)
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
        # if the value is 0.0, we have to set rules what links
        # get what shares. In order to have recursive_factors work properly.
        self.share = 0.0 if constant?
        # To fix https://github.com/dennisschoenmakers/etengine/issues/178
        # we have to change the following line:
        if flexible?
          self.share = 1.0 - lft_input.links.map(&:share).compact.sum.to_f
        end
      end
    end

    # Demands ------------------------------------------------------------------

    # The slot to which the energy for this link flows, irrespective of the
    # links "reversed" setting.
    #
    # Returns a Qernel::Slot.
    def lft_input
      lft_converter.input(@carrier)
    end

    protected :lft_input

    # The slot from where the energy for this link comes, irrespective of the
    # link's "reversed" setting.
    #
    # Returns a Qernel::Slot.
    def rgt_output
      rgt_converter.output(@carrier)
    end

    protected :rgt_output

    # The slot from where the energy for this link comes, for calculation
    # purposes. If the link is reversed it will instead return the slot which
    # receives the link energy.
    #
    # Returns a Qernel::Slot.
    def input
      reversed? ? rgt_output : lft_input
    end

    # The slot that receives the energy of this link. If reversed it will be the
    # lft converter.

    # The slot which receives energy from this link, for calculation purposes.
    # If the link is reversed it will instead return the slot from which the
    # energy comes.
    #
    # Returns a Qernel::Slot.
    def output
      reversed? ? lft_input : rgt_output
    end

    # Optimizations ------------------------------------------------------------

    #######
    private
    #######

    # Internal: Micro-optimization which improves the performance of
    # Array#flatten when the array contains Links.
    #
    # See http://tenderlovemaking.com/2011/06/28/ ...
    #       til-its-ok-to-return-nil-from-to_ary
    def to_ary
      nil
    end
  end # Link
end # Qernel
