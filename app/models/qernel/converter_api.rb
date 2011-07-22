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
    :max_capacity_factor,
    :capacity_factor,
    :land_use_in_nl,
    :technical_lifetime,
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

  # attributes updated by #initialize
  attr_reader :converter, :dataset_key, :dataset_group
  # attributes updated by Converter#graph=
  attr_accessor :area, :graph
  # dataset attributes of converter
  dataset_accessors [:municipality_demand, :preset_demand, :demand]

  # ConverterApi has same accessor as it's converter
  def self.dataset_group
    @dataset_group ||= Qernel::Converter.dataset_group
  end

  def to_s
    converter and converter.full_key.to_s
  end

  def inspect
    to_s
  end


  ##
  #
  #
  def initialize(converter_qernel, attrs = {})
    @converter = converter_qernel
    @dataset_key = converter.dataset_key
    @dataset_group = converter.dataset_group
  end

  ##
  # See {Qernel::Converter} for municipality_demand
  #
  def municipality_demand=(val)
    converter.municipality_demand = val
  end


  ##
  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  def preset_demand=(val)
    converter.preset_demand = val
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

  # creates a method during run time if method_missing
  # 
  def self.create_share_of_converter_method(converter_key)
    key = converter_key.to_sym
    define_method "share_of_#{key}" do
      ol = self.converter.output_links.detect{|l| l.parent.full_key == key}
      ol and ol.share
    end
  end
  
  # creates a method during run time if method_missing and returns the value
  # 
  def self.create_share_of_converter_method_and_execute(caller, converter_key)
    create_share_of_converter_method(converter_key)
    caller.send("share_of_#{converter_key}")
  end

  # creates a method during run time if method_missing
  # 
  def self.create_input_link_method(method_id, carrier_name, side, method)
    if carrier_name.match(/^(.*)_(constant|share|inversedflexible|flexible)$/)
      carrier_name, link_type = carrier_name.match(/^(.*)_(constant|share|inversedflexible|flexible)$/).captures
      link_type = "inversed_flexible" if link_type == "inversedflexible"
    end
    define_method method_id do
      if slot = self.converter.send(side, carrier_name.to_sym)
        if link = link_type.nil? ? slot.links.first : slot.links.detect{|l| l.send("#{link_type}?")}
          link.send(method)
        end
      end
    end
  end

  # creates a method during run time if method_missing and returns the value
  # 
  def self.create_input_link_method_and_execute(caller, method_id, carrier_name, side, method)
    create_input_link_method(method_id, carrier_name, side, method)
    caller.send(method_id)
  end

  def primary_demand
    self.converter.primary_demand
  end

  def final_demand
    self.converter.final_demand
  end

  ##
  #
  #
  def method_missing(method_id, *arguments)
    Rails.logger.info("ConverterApi:method_missing #{method_id}")

    # electricity_      
    if m = /^(.*)_(input|output)_link_(share|value)$/.match(method_id.to_s)
      carrier_name, side, method = m.captures
      self.class.create_input_link_method_and_execute(self, method_id, carrier_name, side, method)
    elsif m = /^share_of_(\w*)$/.match(method_id.to_s) and parent = m.captures.first
      self.class.create_share_of_converter_method_and_execute(self, parent)
    elsif m = /^cost_(\w*)$/.match(method_id.to_s) and method_name = m.captures.first
      self.send(method_name)
    elsif m = /^primary_demand(\w*)$/.match(method_id.to_s)
      # puts arguments
      self.converter.send(method_id, *arguments)
    elsif m = /^final_demand(\w*)$/.match(method_id.to_s)
      self.converter.send(method_id, *arguments)
    else
      Rails.logger.info("ConverterApi#method_missing: #{method_id}")
      super
    end
  end

  # add all the attributes and methods that are modularized in calculator/
  # loads all the "open classes" in calculator
  Dir["app/models/qernel/converter_api/*.rb"].sort.each {|file| require_dependency file }
end
end

