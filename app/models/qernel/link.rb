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

    connect
    memoize_for_cache
  end

  # Creates methods to check for carrier.
  # E.g.: #biogas?
  def method_missing(name, args = nil)
    if name.to_s.last == "?"
      #   def biogas?
      #     carrier.key === :biogas
      #   end
      self.class_eval <<-EOF,__FILE__,__LINE__ +1
        def #{name}
          carrier.#{name}
        end
      EOF
      self.send(name) # dont forget to return the value
    else
      super
    end
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

  def connect
    lft_converter.add_input_link(self)  if lft_converter # only used in testing
    rgt_converter.add_output_link(self) if rgt_converter  # only used in testing
  end

  def memoize_for_cache
    @is_loss = @carrier.andand.id == 1

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

  def calculated_by_left?
    !calculated_by_right?
  end

  def calculated_by_right?
    (dependent? or inversed_flexible? or ((constant? and self.share.nil?) == true)) || reversed?
  end

  def max_demand
    dataset_get(:max_demand) || rgt_converter.query.max_demand
  end

  def priority
    dataset_get(:priority) || 1_000_000
  end

  # Does link have min-/max_demand?
  # Important to figure out for which flexible links to calculate first.
  def max_boundaries?
    flexible? && max_demand
  end

  # --------- Calculation ------------------------------------------------------

  def calculate
    if self.calculated != true
      self.value = self.send("calculate_#{@link_type}")
      self.calculated = true
    end
    self.value
  end

  # Updates the shares according to demand.
  # This is needed so that recursive_factors work correctly.
  #
  def update_share
    demand = lft_external_demand
    if self.value and demand and demand > 0
      self.share = self.value / demand
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

protected
  # --------- Calculation -----------------------------------------------------

  # If share is set to NIL, take the parent converter demand
  #
  def calculate_constant
    if self.share.nil?
      val = output_external_demand
      raise "Constant Link with share = nil expects a demand of child converter #{rgt_converter.key}" if val.nil?
      val
    else
      self.share
    end
  end

  def calculate_dependent
    #calculate_flexible
    output_external_demand
  end

  def calculate_share
    share * input_external_demand
  rescue => e
    raise "Share is nil for the following link:\n#{inspect}" if share.nil?
    raise "input_external_demand is nil for the following link:\n#{inspect}" if input_external_demand.nil?
    raise e
  end


  # Inversed flexible links take any excess energy from a slot which isn't
  # assigned to be carried through another link.
  #
  # Inversed Flexible shouldn't become negative.
  # https://github.com/dennisschoenmakers/etengine/issues/194
  #
  def calculate_inversed_flexible
    output = rgt_converter.demand * rgt_output.conversion
    excess = output - rgt_output.external_link_value

    (excess < 0.0) ? 0.0 : excess
  end

  #
  #
  def calculate_flexible
    total_demand = input_external_demand
    return nil if total_demand.nil?

    inp = input
    already_supplied_demand = (inp and inp.external_value) || 0.0
    new_value = total_demand - already_supplied_demand

    apply_boundaries(new_value)
  end


  # Make sure that the value is greater than the min_value and smaller
  # than the max_value.
  #
  # @param value [Float] value
  # @return [0.0,Float]
  #
  def apply_boundaries(new_value)
    min = min_demand
    max = max_demand
    if min.present? && new_value < min
      min
    elsif max.present? && new_value > max
      max
    else
      new_value
    end
  end


  # --------- Demands ---------------------------------------------------------

  # This method overwrites the min_demand dataset_accessor. min_demand is by default 0.0
  # Except for electricity import/export, where it should be -Infinity. We use nil instead.
  #
  def min_demand
    # Default min_demand of flexible is 0.0 (no negative energy)
    # Exception being electricity import/export. where -energy = export
    if flexible? && !@carrier.electricity? && !rgt_converter.energy_import_export?
      0.0
    elsif flexible? && lft_converter.has_loop?
      # typically a loop contains an inversed_flexible (left) and a flexible
      # (right) to the same converter. When too much energy overflow into
      # inversed, when too little flow into flexible.
      # Sometimes this construct does not work properly, so we manually make
      # sure a flexible can go below 0.0.
      # If you remove that you will get *stackoverflow problems for primary_demand*,
      # when both links have a non 0.0 value (because of the == check in recursive_factor).
      # causing a loop in the recursive_factor. Forcing a 0.0 on the flex link closes the loop.
      0.0
    else
      nil
    end
  end

  # The external demand of the converter to the left.
  def output_external_demand
    output.expected_external_value || 0.0
  end

  # What is the demand of the link input. For reversed links we use the demand
  # of the rgt converter otherwise the lft one.
  def input_external_demand
    input && input.expected_external_value || 0.0
  end

  # The external demand of the converter to the left.
  def lft_external_demand
    lft_input = self.lft_input
    lft_input && lft_input.expected_external_value || 0.0
  end

  # slot of lft converter
  def lft_input
    lft_converter.input(@carrier)
  end

  # slot of rgt converter
  def rgt_output
    rgt_converter.output(@carrier)
  end

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
