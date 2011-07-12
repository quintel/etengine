module Qernel
##
#
#
class Link
  extend ActiveModel::Naming
  include DatasetAttributes

  DATASET_ATTRIBUTES = [
    :share, :value, :calculated
  ]

  attr_accessor :graph
  ##
  # Parent is the converter to the left (towards useful demand)
  #
  attr_accessor :parent
  ##
  # Parent is the converter to the right (towards useful primary demand)
  #
  attr_accessor :child
  attr_accessor :carrier
  attr_reader :link_type, :id, :parent_id, :child_id, :carrier_id

  dataset_accessors DATASET_ATTRIBUTES

  def initialize(id, parent, child, carrier, link_type)
    @id = id
    @parent, @child, @carrier, @link_type = parent, child, carrier, link_type.to_sym
    @parent.add_input_link(self) if @parent # only used in testing
    @child.add_output_link(self) if @child  # only used in testing
    self.dataset_key # memoize dataset_key
  end

  def name
    "#{@parent.name} <- #{@child.name}"
  end

  def loss?
    @carrier.id == 1
  end

  def inspect
    "<Link parent:#{@parent.id} child:#{@child.id} share:#{share} value:#{value} carrier:#{@carrier.key}>"
  end


  #########################
  # LINK TYPES
  #########################

  def share?
    link_type === :share
  end

  def flexible?
    link_type === :flexible
  end

  def inversed_flexible?
    link_type === :inversed_flexible
  end

  def dependent?
    link_type === :dependent
  end

  def constant?
    link_type === :constant
  end

  #########################
  # CALCULATION  FLOW
  #########################

  # TODO: Rename to calculated_by_input and calculated_by_output
  #
  def calculated_by_parent?
    !calculated_by_child?
  end

  def calculated_by_child?
    dependent? or inversed_flexible? or ((constant? and self.share.nil?) == true)
  end

  ##
  # Calculates the {#value} based on the parents demand
  #
  # == {#dependent?}
  # take the supply for this links carrier from the child converter
  #
  # == {#constant?}
  # take the value defined in {#share} as the links value
  #
  # == {#share?}
  # share * demand
  #
  # == {#flexible?}
  # total_demand - already_supplied_links
  #
  def calculate
    if self.calculated != true
      self.value = self.send("calculate_#{link_type}")
      self.calculated = true
    end
    self.value
  end

  def assign_share
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

private

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

  ##
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
    output.andand.expected_external_value || 0.0
  end

  def calculate_share
    self.share * input_external_demand
  end

  ##
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

  ##
  #
  #
  def calculate_flexible
    total_demand = input_external_demand
    return nil if total_demand.nil?

    already_supplied_demand = input.andand.external_passive_link_value || 0.0
    new_value = total_demand - already_supplied_demand

    lower_boundary_for_flexible(new_value)
  end

  ##
  # Flexible links take the remainder, so it can also become negative.
  # This is only allowed if the carrier is electricity, steam_hot_water
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
end


end
