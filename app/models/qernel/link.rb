module Qernel
##
#
#
class Link
  extend ActiveModel::Naming

  # --------- Dataset ---------------------------------------------------------

  include DatasetAttributes

  DATASET_ATTRIBUTES = [
    :share,
    :value,
    :max_demand,
    :priority,
    :calculated,
    :country_specific
  ]

  dataset_accessors DATASET_ATTRIBUTES

  def self.dataset_group; :graph; end

  # --------- Accessor ---------------------------------------------------------

  attr_accessor :graph, # needed for dataset
                :rgt_converter, # Parent is the converter to the left (towards useful demand)
                :lft_converter,  # Child is the converter to the right (towards useful primary demand)
                :carrier

  attr_reader :id,
              :link_type,
              :key,
              :groups


  # --------- Flow ------------------------------------------------------------

  attr_accessor :reversed
  attr_reader :is_loss

  alias reversed? reversed
  alias loss? is_loss

  alias_method :demand, :value

  # ----- Micro optimization -------------------------------------------------

  # make Array#flatten fast
  attr_reader :to_ary

  # --------- Link Types ------------------------------------------------------

  attr_reader :is_share, :flexible, :dependent, :constant, :inversed_flexible

  alias share? is_share
  alias flexible? flexible
  alias dependent? dependent
  alias constant? constant
  alias inversed_flexible? inversed_flexible


  # --------- Initialize ------------------------------------------------------

  def initialize(id, lft, rgt, carrier, link_type, reversed = false, groups = [])
    @key = id
    @id = id.is_a?(Numeric) ? id : Hashpipe.hash(id)

    @reversed      = reversed
    @lft_converter = lft
    @rgt_converter = rgt
    @carrier       = carrier
    @groups        = groups

    self.link_type = link_type.to_sym

    lft_converter.add_input_link(self)
    rgt_converter.add_output_link(self)

    memoize_for_cache
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

protected

  def memoize_for_cache
    @is_loss = @carrier.loss?
    self.dataset_key # memoize dataset_key
  end

  def link_type=(link_type)
    @link_type = link_type

    @is_share          = @link_type === :share
    @flexible          = @link_type === :flexible
    @inversed_flexible = @link_type === :inversed_flexible
    @dependent         = @link_type === :dependent
    @constant          = @link_type === :constant
  end

  # --------- Calculation Flow -------------------------------------------------

public

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

  # --------- Calculation ------------------------------------------------------

  def calculate
    unless self.calculated
      self.value      = LinkCalculation.for(self).call(self)
      self.calculated = true
    end

    self.value
  end

  # Updates the shares according to demand.
  # This is needed so that recursive_factors work correctly.
  #
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

  # --------- Demands ---------------------------------------------------------

  protected

  # slot of lft converter
  def lft_input
    lft_converter.input(@carrier)
  end

  # slot of rgt converter
  def rgt_output
    rgt_converter.output(@carrier)
  end

  public

  # The slot from where the energy for this link comes. If reversed it will be
  # the rgt converter.
  def input
    reversed? ? rgt_output : lft_input
  end

  # The slot that receives the energy of this link. If reversed it will be the
  # lft converter.
  def output
    reversed? ? lft_input : rgt_output
  end


  # --------- Debug -----------------------------------------------------------

public

  def carrier_key
    carrier and carrier.key
  end

  def inspect
    "<Qernel::Link #{key.inspect}>"
  end

  # TODO: find better names and explanation, this was added for the upcoming input module
  # and this attribute is used on the converter page. Slot has a similar method
  def kind
    case country_specific
    when 0 then :red
    when 1 then :yellow
    when 2 then :green
    end
  end
end


end
