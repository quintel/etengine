module Qernel
##
#
#
class Link
  extend ActiveModel::Naming

  # --------- Dataset ---------------------------------------------------------

  include DatasetAttributes

  DATASET_ATTRIBUTES = [
    :share, :value, :calculated
  ]

  dataset_accessors DATASET_ATTRIBUTES


  # --------- Accessor ---------------------------------------------------------

  attr_accessor :graph,
                :parent, # Parent is the converter to the left (towards useful demand)
                :child,  # Child is the converter to the right (towards useful primary demand)
                :carrier 

  attr_reader :id,
              :link_type


  # --------- Flow ------------------------------------------------------------

  attr_reader :reverse, 
              :is_loss

  alias reverse? reverse
  alias loss? is_loss


  # --------- Link Types ------------------------------------------------------

  attr_reader :is_share, :flexible, :dependent, :constant, :inversed_flexible

  alias share? is_share
  alias flexible? flexible
  alias dependent? dependent
  alias constant? constant
  alias inversed_flexible? inversed_flexible


  # --------- Initialize ------------------------------------------------------

  def initialize(id, parent, child, carrier, link_type, reverse = false)
    @id = id
    @reverse = reverse
    @parent, @child, @carrier, @link_type = parent, child, carrier, link_type.to_sym

    connect
    memoize_for_cache
  end

protected

  def connect
    @parent.add_input_link(self) if @parent # only used in testing
    @child.add_output_link(self) if @child  # only used in testing
  end

  def memoize_for_cache
    @is_loss = @carrier.id == 1
    @is_share = @link_type === :share
    @flexible = @link_type === :flexible
    @inversed_flexible = @link_type === :inversed_flexible
    @dependent = @link_type === :dependent
    @constant = @link_type === :constant

    self.dataset_key # memoize dataset_key
  end


  # --------- Calculation Flow -------------------------------------------------

public

  # TODO: Rename to calculated_by_input and calculated_by_output
  #
  def calculated_by_left?
    !calculated_by_right?
  end

  def calculated_by_right?
    !reverse? && 
      (dependent? or inversed_flexible? or ((constant? and self.share.nil?) == true))
  end


  # --------- Calculation ------------------------------------------------------

  def calculate
    if self.calculated != true
      self.value = self.send("calculate_#{link_type}")
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

  # If share is set to NIL, take the parent converter demand
  #
  def calculate_constant
    if self.share.nil?
      val = output_external_demand || 0.0
      raise "Constant Link with share = nil expects a demand of child converter #{@child.full_key}" if val.nil?
      val
    else
      self.share
    end
  end

  def calculate_dependent
    o = output
    (o and o.expected_external_value) || 0.0
  end

  def calculate_share
    self.share * input_external_demand
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
    already_supplied_demand = (inp and inp.external_passive_link_value) || 0.0
    new_value = total_demand - already_supplied_demand

    lower_boundary_for_flexible(new_value)
  end


  # Flexible links take the remainder, so it can also become negative.
  # This is only allowed if the carrier is electricity 
  # or for the energy_import_export converter.
  #
  # @param value [Float] value
  # @return [0.0,Float]
  #
  def lower_boundary_for_flexible(new_value)
    # 2010-06-14 changed back to not let heat carriers go below 0.0
    # if new_value < 0.0 and !@carrier.electricity? and !@child.energy_import_export? and !@carrier.steam_hot_water?
    if new_value < 0.0 and !@carrier.electricity? and !@child.energy_import_export?
      0.0
    else
      new_value
    end
  end


  # --------- Demands ---------------------------------------------------------

  def output_external_demand
    out = output
    (out and out.expected_external_value) || 0.0
  end

  def input_external_demand
    inp = input
    (inp and inp.expected_external_value) || 0.0
  end

  def input
    @parent.input(@carrier)
  end

  def output
    @child.output(@carrier)
  end


  # --------- Debug -----------------------------------------------------------

public

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


end


end
