module Qernel


##
# == Big Picture
#
# === Converter
# Responsible for calculating demands/energy flow only. Has links and
# slots, so can traverse the graph. But doesn't know about its other
# attributes like cost, co2, etc. It is more like a node in a graph.
#
# === ConverterApi
# 
# A ConverterApi instance includes (static) attributes (stored in the
# ::Converter table) and dynamic attributes that are calculated based 
# on the static ones. It doesn't (really) know about links, slots, etc
# but can access them through #converter. It's more like a data-model.
#
#
# === Reasons for separation
#
# Converter is relatively simple, ConverterApi has a lot of code. Like 
# this we can keep the calculation part simple. Also regarding that in
# the future it might be easier to implement the graph for instance in
# another language (C, Java, Scala).
#
# In the energy flow calculation, we worry about speed much more. Things
# like method_missing can make that really slow, (e.g. calling flatten)
# on an array of objects that implement method_missing degrades performance
# a lot.
#
# 
#
#
# You can use all the methods directly in the GQL. *Do not miss* the 
# *Dynamic Method Handling* section.
#
#
#
class ConverterApi
  include MethodMetaData
  include DatasetAttributes

  ##
  # :method: primary_demand_of_fossil
  # Primary demand of fossil energy

  EXPECTED_DEMAND_TOLERANCE = 0.001

  # All the static attributes that come from the database
  # Access the following attributes with @. e.g
  #   @max_capacity_factor *and not* max_capacity_factor (or self.max_capacity_factor)
  ATTRIBUTES_USED = [
    :demand_expected_value,
    :typical_capacity_gross_in_mj_s,
    :typical_capacity_effective_in_mj_s,
    :typical_thermal_capacity_effective_in_mj_yr,
    :max_capacity_factor,
    :capacity_factor,
    :land_use_in_nl,
    :technical_lifetime,
    :technological_maturity,
    :lead_time,
    :construction_time,
    :cost_om_fixed_per_mj,
    :cost_om_variable_ex_fuel_co2_per_mj,
    :cost_co2_capture_ex_fuel_per_mj,
    :cost_co2_transport_and_storage_per_mj,
    :cost_fuel_other_per_mj,
    :overnight_investment_ex_co2_per_mj_s,
    :overnight_investment_co2_capture_per_mj_s,
    :sustainable,
    :mainly_baseload,
    :intermittent,
    :cost_co2_expected_per_mje,
    :co2_production_kg_per_mj_output,
    :installed_capacity_effective_in_mj_s,
    :electricitiy_production_actual, # TODO typo (from:jape)
    :wacc,
    :co2_free,
    :peak_load_units_present,
    :simult_wd,
    :simult_sd,
    :simult_we,
    :simult_se,
    :typical_electric_capacity,
    :typical_heat_capacity,
    :full_load_hours,
    :operation_hours,
    :operation_and_maintenance_cost_fixed_per_mw_input,
    :operation_and_maintenance_cost_variable_per_full_load_hour,
    :investment,
    :purchase_price,
    :installing_costs,
    :economic_lifetime,
    :typical_nominal_input_capacity,
    :fixed_operation_and_maintenance_cost_per_mw_input,
    :residual_value_per_mw_input,
    :decommissioning_costs_per_mw_input,
    :purchase_price_per_mw_input,
    :installing_costs_per_mw_input,
    :part_ets,
    :decrease_in_nomimal_capacity_over_lifetime,
    :ccs_operation_and_maintenance_cost_per_full_load_hour,
    :ccs_investment_per_mw_input
  ]

  dataset_accessors ATTRIBUTES_USED

  ##
  # The converter all calculations are based on
  #
  attr_reader :converter

  def dataset
    converter.dataset
  end

  ##
  # Returns the unique key for this object that is used in Dataset.
  #
  def dataset_key
    converter.dataset_key
  end

  def area
    converter.graph.area
  end

  def to_s
    converter and converter.full_key.to_s
  end

  def inspect
    converter.full_key.to_s
  end


  ##
  #
  #
  def initialize(converter_qernel, attrs = {})
    @converter = converter_qernel
  end


  ##
  # See {Qernel::Converter} for municipality_demand
  #
  def municipality_demand
    converter.municipality_demand
  end
  register_calculation_method :municipality_demand

  ##
  # See {Qernel::Converter} for municipality_demand
  #
  def municipality_demand=(val)
    converter.municipality_demand = val
  end

  ##
  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  def preset_demand
    converter.preset_demand
  end

  ##
  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  def preset_demand=(val)
    converter.preset_demand = val
  end

  ##
  # The total energy demand of the converter
  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  # @return [Float] total energy demand
  #
  def demand
    converter.demand
  end

  ##
  # Is the calculated near the demand_expected_value?
  #
  # @return [nil] if demand or expected is nil
  # @return [true] if demand is within tolerance EXPECTED_DEMAND_TOLERANCE
  #
  def demand_expected?
    expected = demand_expected_value
    return nil if demand.nil? or expected.nil?

    return true if demand.to_f == 0 and expected.to_f == 0.0
    (demand.to_f / expected.to_f - 1.0).abs < EXPECTED_DEMAND_TOLERANCE
  end

  # Extracted into a method, because we have a circular dependency in specs
  # Carriers are not imported, so when initializing all those methods won't get
  # loaded. So this way we can load later.
  def self.create_methods_for_each_carrier(carrier_names)
    carrier_names.each do |carrier|
      carrier_key = carrier.to_sym
      define_method "demand_of_#{carrier}" do
        self.output_of_carrier(carrier_key)
      end
      define_method "supply_of_#{carrier}" do
        self.input_of_carrier(carrier_key)
      end
      define_method "input_of_#{carrier}" do
        self.input_of_carrier(carrier_key)
      end
      define_method "output_of_#{carrier}" do
        self.output_of_carrier(carrier_key)
      end
      define_method "primary_demand_of_#{carrier}" do
        converter.primary_demand_of_carrier(carrier_key)
      end

      ['input', 'output'].each do |side|
        define_method "#{carrier}_#{side}_link_share" do
          if slot = self.converter.send(side, carrier_key)
            if link = slot.links.first
              link.send('share')
            end
          end
        end

        %w[conversion value share actual_conversion].each do |method|
          define_method "#{carrier}_#{side}_#{method}" do
            slot = self.converter.send(side, carrier_key)
            slot and slot.send(method)
          end
        end
      end
    end
  end

  create_methods_for_each_carrier(::Carrier.all.map(&:key))


  def primary_demand
    self.converter.primary_demand
  end

  def final_demand
    self.converter.final_demand
  end

  ##
  #
  #
  # @overload output_of_CARRIER
  #   The output of a specific carrier.
  #   e.g.
  #     output_of_electricity
  #   @param CARRIER [String] carrier_key
  #   @return [Float] energy output of carrier
  #
  # @overload input_of_CARRIER
  #   The input of a specific carrier.
  #   e.g.
  #     input_of_electricity
  #   @param CARRIER [String] carrier_key
  #   @return [Float] energy input of carrier
  #
  # @overload primary_demand_of_CARRIER
  #   Primary demand of a specific carrier
  #   e.g.
  #     primary_demand_of_electricity
  #   @return [Float]
  #
  # @overload primary_demand_of_sustainable
  #   Primary demand of sustainable energy
  #   @return [Float]
  #
  # @overload primary_demand
  #   The primary energy demand of a converter
  #   @return [Float]
  #
  # @overload final_demand
  #   The final energy demand of a converter
  #   @return [Float]
  #
  # @overload CARRIER_DIRECTIION_link_ATTRIBUTE
  #   Attribute (ATTRIBUTE: share or value) of the *first* link with
  #   CARRIER and DIRECTION (input or output).
  #   e.g.
  #     electricity_input_link_share
  #     natural_gas_output_link_value
  #
  #   @param CARRIER [String] carrier_key
  #   @param DIRECTION ['input','output']
  #   @param ATTRIBUTE [conversion,value,share,actual_conversion]
  #   @return [Float]
  #
  # @overload share_of_OUTPUT_CONVERTER_KEY
  #   @param OUTPUT_CONVERTER_KEY [String] is the key of a converter on the output side.
  #   @return [Float]
  #
  # @output CARRIER_DIRECTION_ATTRIBUTE
  #   Slot attributes
  #   e.g.
  #     electricity_input_conversion
  #   @param CARRIER [String] carrier_key
  #   @param DIRECTION ['input','output']
  #   @param ATTRIBUTE [String] attribute of slot
  #   @return [Float]
  #
  def method_missing(method_id, *arguments)
    # Rails.logger.info("ConverterApi:method_missing #{method_id}")

    # electricity_
    if m = /^share_of_(\w*)$/.match(method_id.to_s) and parent = m.captures.first
      self.converter.output_links.select{|l| l.parent.full_key.to_s == parent.to_s}.first.andand.share
    elsif m = /^(.*)_(input|output)_link_(share|value)$/.match(method_id.to_s)
      carrier_name, side, method = m.captures
      if carrier_name.match(/^(.*)_(constant|share|inversedflexible|flexible)$/)
        carrier_name, link_type = carrier_name.match(/^(.*)_(constant|share|inversedflexible|flexible)$/).captures
        link_type = "inversed_flexible" if link_type == "inversedflexible"
      end
      if slot = self.converter.send(side, carrier_name.to_sym)
        if link = link_type.nil? ? slot.links.first : slot.links.detect{|l| l.send("#{link_type}?")}
          link.send(method)
        end
      end
    elsif m = /^cost_(\w*)$/.match(method_id.to_s) and method_name = m.captures.first
      self.send(method_name)
    elsif m = /^primary_demand(\w*)$/.match(method_id.to_s)
      # puts arguments
      self.converter.send(method_id, *arguments)
    elsif m = /^final_demand(\w*)$/.match(method_id.to_s)
      self.converter.send(method_id, *arguments)
    else
      puts method_id
      super
    end
  end

  # add all the attributes and methods that are modularized in calculator/
  # loads all the "open classes" in calculator
  Dir["app/models/qernel/converter_api/*.rb"].sort.each {|file| require_dependency file }
end
end

