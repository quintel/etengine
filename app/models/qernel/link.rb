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
    :calculated
  ]

  dataset_accessors DATASET_ATTRIBUTES


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

  def initialize(id, parent, child, carrier, link_type, reversed = false)
    @id = id
    @reversed = reversed
    @parent, @child, @carrier = parent, child, carrier
    
    self.link_type = link_type

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
    #   puts(self.graph_parser_expression)
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
      self.share = 1.0 if flexible?
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
  end


  # Total converter demand - SUM(outputs.external_link_value)
  # we take the external_link_values because slots that have
  # inversed_flexible links are dynamic. So they do cannot have
  # fixed conversions (and thus no valid internal_link_values).
  #
  #
  def calculate_inversed_flexible
    #raise "#{@child.full_key} has no demand" if @child.demand.nil?
    @child.demand - @child.outputs.map(&:external_link_value).compact.sum
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


  # --------- Debug -----------------------------------------------------------

public

  def carrier_key
    carrier and carrier.key
  end

  def graph_parser_expression
    slot_data = [
      "#{input.andand.conversion}",
      "#{output.andand.conversion}"
    ].join(';')
    str = "#{@carrier.key}[#{slot_data}]: "
    str += "#{@parent.andand.key}(#{@parent.andand.demand || nil})"
    str += " == #{@link_type.to_s[0]}(#{self.share || nil}) ==> "
    str += "#{@child.andand.key}(#{@child.andand.demand || nil})"
    str
  end

  def name
    "#{@parent.name} <- #{@child.name}"
  end

  def inspect
    "<Link parent:#{@parent.id} child:#{@child.id} share:#{share} value:#{value} carrier:#{@carrier.key}>"
  end

  # Helper method to get the associated active_record object.
  def ar_object
    @ar_object ||= ::Link.find(id)
  end
end


end
