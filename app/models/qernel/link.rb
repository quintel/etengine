module Qernel
##
#
#
class Link
  extend ActiveModel::Naming
  include Topology::Link

  # --------- Dataset ---------------------------------------------------------

  include DatasetAttributes

  DATASET_ATTRIBUTES = [
    :share, 
    :value, 
    :max_demand, 
    :calculated,
    :country_specific
  ]

  dataset_accessors DATASET_ATTRIBUTES

  def self.dataset_group; :graph; end
  
  # --------- Accessor ---------------------------------------------------------

  attr_accessor :graph, # needed for dataset
                :parent, # Parent is the converter to the left (towards useful demand)
                :child,  # Child is the converter to the right (towards useful primary demand)
                :carrier 

  attr_reader :id,
              :link_type


  # --------- Flow ------------------------------------------------------------

  attr_accessor :reversed
  attr_reader :is_loss

  alias reversed? reversed
  alias loss? is_loss


  # --------- Link Types ------------------------------------------------------

  attr_reader :is_share, :flexible, :dependent, :constant, :inversed_flexible

  alias share? is_share
  alias flexible? flexible
  alias dependent? dependent
  alias constant? constant
  alias inversed_flexible? inversed_flexible


  # --------- Initialize ------------------------------------------------------

  def initialize(id, input, output, carrier, link_type, reversed = false)
    @id = id.is_a?(Numeric) ? id : Hashpipe.hash(id)

    @reversed = reversed
    @parent, @child, @carrier = input, output, carrier
    
    self.link_type = link_type.to_sym

    connect
    memoize_for_cache
  end

protected

  def connect
    @parent.add_input_link(self) if @parent # only used in testing
    @child.add_output_link(self) if @child  # only used in testing
  end

  def memoize_for_cache
    @is_loss = @carrier.andand.id == 1

    self.dataset_key # memoize dataset_key
  end

  def link_type=(link_type)
    @link_type = link_type

    @is_share = @link_type === :share
    @flexible = @link_type === :flexible
    @inversed_flexible = @link_type === :inversed_flexible
    @dependent = @link_type === :dependent
    @constant = @link_type === :constant
  end

  def after_assign_object_dataset
    # if self.dependent?
    #   @reversed = true
    # end
  end


  # --------- Calculation Flow -------------------------------------------------

public

  # TODO: Rename to calculated_by_input and calculated_by_output
  #
  def calculated_by_left?
    !calculated_by_right?
  end

  def calculated_by_right?
    (dependent? or inversed_flexible? or ((constant? and self.share.nil?) == true)) || reversed?
  end

  # Does link have min-/max_demand? 
  # Important to figure out for which flexible links to calculate first.
  #
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
  # This is needed so that wouter_dances work correctly.
  #
  def update_share
    demand = input_external_demand
    if self.value and demand and demand > 0
      self.share = self.value / demand
    elsif value == 0.0
      # if the value is 0.0, we have to set rules what links
      # get what shares. In order to have wouter_dances work properly.
      self.share = 0.0 if constant?
      # To fix https://github.com/dennisschoenmakers/etengine/issues/178
      # we have to change the following line:
      if flexible?
        self.share = 1.0 - input.links.map(&:share).compact.sum.to_f
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
      raise "Constant Link with share = nil expects a demand of child converter #{@child.full_key}" if val.nil?
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


  # Total converter demand - SUM(outputs.external_link_value)
  # we take the external_link_values because slots that have
  # inversed_flexible links are dynamic. So they do cannot have
  # fixed conversions (and thus no valid internal_link_values).
  #
  # Inversed Flexible shouldn't become negative.
  # https://github.com/dennisschoenmakers/etengine/issues/194
  # 
  def calculate_inversed_flexible
    #raise "#{@child.full_key} has no demand" if @child.demand.nil?
    result = @child.demand - @child.outputs.map(&:external_link_value).compact.sum
    (result < 0.0) ? 0.0 : result
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
    if flexible? && !@carrier.electricity? && !@child.energy_import_export?
      0.0
    elsif flexible? && @parent.has_loop?
      # typically a loop contains an inversed_flexible (left) and a flexible 
      # (right) to the same converter. When too much energy overflow into
      # inversed, when too little flow into flexible. 
      # Sometimes this construct does not work properly, so we manually make
      # sure a flexible can go below 0.0.
      # If you remove that you will get *stackoverflow problems for primary_demand*, 
      # when both links have a non 0.0 value (because of the == check in wouter_dance).
      # causing a loop in the wouter_dance. Forcing a 0.0 on the flex link closes the loop.
      0.0
    else
      nil
    end
  end

  def output_external_demand
    output.expected_external_value || 0.0
  end

  def input_external_demand
    input && input.expected_external_value || 0.0
  end

  def input
    reversed? ? @child.output(@carrier) : @parent.input(@carrier)
  end

  def output
    reversed? ? @parent.input(@carrier) : @child.output(@carrier)
  end

public

  # used by primary_demand
  def to_environment?
    child.environment?
  end

  # --------- Debug -----------------------------------------------------------

public

  def carrier_key
    carrier and carrier.key
  end

  def inspect
    "<Qernel::Link #{topology_key}>"
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
