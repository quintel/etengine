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
  #   @demand_expected_value *and not* demand_expected_value (or self.demand_expected_value)
  ATTRIBUTES_USED = [
    :availability,
    :variability,
    :capacity_factor,
    :ccs_investment_per_mw_input,
    :ccs_operation_and_maintenance_cost_per_full_load_hour,
    :co2_free,
    :construction_time,
    :costs_per_mj,
    :decommissioning_costs_per_mw_input,
    :decrease_in_nomimal_capacity_over_lifetime,
    :demand_expected_value,
    :full_load_hours,
    :installing_costs_per_mw_input,
    :land_use_per_unit,
    :lead_time,
    :network_capacity_available_in_mw,
    :network_capacity_used_in_mw,
    :network_expansion_costs_in_euro_per_mw,
    :operation_and_maintenance_cost_fixed_per_mw_input,
    :operation_and_maintenance_cost_variable_per_full_load_hour,
    :part_ets,
    :peak_load_units_present,
    :purchase_price_per_mw_input,
    :residual_value_per_mw_input,
    :simult_sd,
    :simult_se,
    :simult_wd,
    :simult_we,
    :technical_lifetime,
    :typical_nominal_input_capacity,
    :wacc
  ]
  
  # For the data/converter/show page we need grouping of the attributes
  # these atrribut groups should only be used to show the values in the data section
  
  ELECTRICITY_PRODUCTION_VALUES  =  {
    :technical => {
      :nominal_capacity_electricity_output_per_unit => ['Nominal electrical capacity','MW'],
      :average_effective_output_of_nomimal_capacity_over_lifetime => ['Average effective output of nomimal capacity over lifetime', '%'],
      :full_load_hours  => ['Full load hours', 'hour / year'],
      :electricity_output_conversion  => ['Electrical efficiency', '%'],
      :heat_output_conversion  => ['Heat efficiency', '%']
    },
    :cost => {
      :initial_investment_excl_ccs_per_mwe => ['Initial investment (excl CCS)', 'euro / MWe'],
      :additional_investment_ccs_per_mwe => ['Additional inititial investment for CCS', 'euro / MWe'],
      :cost_of_installing_per_mwe => ['Cost of installing','euro / MWe'],
      :residual_value_per_mwe => ['Residual value after lifetime','euro / MWe'],
      :decommissioning_costs_per_mwe => ['Decommissioning costs','euro / MWe'],
      :fixed_yearly_operation_and_maintenance_costs_per_mwe => ['Fixed operation and maintenance costs','euro / MWe / year'],
      :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs (excl CCS)', 'euro / full load hour'],
      :ccs_operation_and_maintenance_cost_per_full_load_hour  => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour'],
      :wacc  => ['Weighted average cost of capital', '%'],
      :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']      
    },
    :other => {
      :land_use_per_unit  => ['Land use per unit', 'km2'],
      :construction_time  => ['Construction time', 'year'],
      :technical_lifetime  => ['Technical lifetime', 'year']      
    }
  }

  HEAT_PRODUCTION_VALUES  =  {
    :technical => {
      :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
      :average_effective_output_of_nomimal_capacity_over_lifetime => ['Average effective output of nomimal capacity over lifetime', '%'],
      :full_load_hours  => ['Full load hours', 'hour / year'],
      :heat_output_conversion  => ['Heat efficiency', '%']
    },
    :cost => {
      :purchase_price_per_unit => ['Initial purchase price', 'euro'],
      :cost_of_installing_per_unit => ['Cost of installing','euro'],
      :residual_value_per_unit => ['Residual value after lifetime','euro'],
      :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
      :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
      :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs', 'euro / full load hour'],
      :wacc  => ['Weighted average cost of capital', '%'],
      :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']      
    },
    :other => {
      :land_use_per_unit  => ['Land use per unit', 'km2'],
      :technical_lifetime  => ['Technical lifetime', 'year']      
    }
  }
  
  HEAT_PUMP_VALUES  =  {
    :technical => {
      :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
      :average_effective_output_of_nomimal_capacity_over_lifetime => ['Average effective output of nomimal capacity over lifetime', '%'],
      :full_load_hours  => ['Full load hours', 'hour / year'],
      :coefficient_of_performance => ['Coefficient of performance', ''],
      :heat_output_conversion  => ['Heat efficiency (after COP)', '%']
    },
    :cost => {
      :purchase_price_per_unit => ['Initial purchase price', 'euro'],
      :cost_of_installing_per_unit => ['Cost of installing','euro'],
      :residual_value_per_unit => ['Residual value after lifetime','euro'],
      :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
      :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
      :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs', 'euro / full load hour'],
      :wacc  => ['Weighted average cost of capital', '%'],
      :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']      
    },
    :other => {
      :land_use_per_unit  => ['Land use per unit', 'km2'],
      :technical_lifetime  => ['Technical lifetime', 'year']      
    }
  }
  
  CHP_VALUES  =  {
    :technical => {
      :nominal_capacity_electricity_output_per_unit => ['Nominal electrical capacity','MW'],
      :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
      :average_effective_output_of_nomimal_capacity_over_lifetime => ['Average effective output of nomimal capacity over lifetime', '%'],
      :full_load_hours  => ['Full load hours', 'hour / year'],
      :electricity_output_conversion  => ['Electrical efficiency', '%'],
      :heat_output_conversion  => ['Heat efficiency', '%']
    },
    :cost => {
      :initial_investment_excl_ccs_per_unit => ['Initial investment (excl CCS)', 'euro'],
      :additional_investment_ccs_per_unit => ['Additional inititial investment for CCS', 'euro'],
      :cost_of_installing_per_unit => ['Cost of installing','euro'],
      :residual_value_per_unit => ['Residual value after lifetime','euro'],
      :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
      :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
      :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs (excl CCS)', 'euro / full load hour'],
      :ccs_operation_and_maintenance_cost_per_full_load_hour  => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour'],
      :wacc  => ['Weighted average cost of capital', '%'],
      :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']      
    },
    :other => {
      :land_use_per_unit  => ['Land use per unit', 'km2'],
      :construction_time  => ['Construction time', 'year'],
      :technical_lifetime  => ['Technical lifetime', 'year']      
    }
  }
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
    converter && converter.full_key.to_s
  end

  def inspect
    to_s
  end

  # For testing only
  # Otherwise graphs by GraphParser won't be Gqueryable
  # DEBT properly fix
  if Rails.env.development? or Rails.env.test?
    def object_dataset
      converter.object_dataset
    end
  end

  #
  #
  def initialize(converter_qernel, attrs = {})
    @converter = converter_qernel
    @dataset_key = converter.dataset_key
    @dataset_group = converter.dataset_group
  end

  def energy_balance_group
    converter.energy_balance_group
  end

  # See {Qernel::Converter} for municipality_demand
  #
  def municipality_demand=(val)
    converter.municipality_demand = val
  end


  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  def preset_demand=(val)
    converter.preset_demand = val
  end

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
        self.output_of_carrier(carrier_key) || 0.0
      end
      define_method "supply_of_#{carrier}" do
        self.input_of_carrier(carrier_key) || 0.0
      end
      define_method "input_of_#{carrier}" do
        self.input_of_carrier(carrier_key) || 0.0
      end
      define_method "output_of_#{carrier}" do
        self.output_of_carrier(carrier_key) || 0.0
      end
      define_method "primary_demand_of_#{carrier}" do
        converter.primary_demand_of_carrier(carrier_key) || 0.0
      end

      ['input', 'output'].each do |side|
        define_method "#{carrier}_#{side}_link_share" do
          if slot = self.converter.send(side, carrier_key)
            if link = slot.links.first
              link.send('share') || 0.0
            else
              0.0
            end
          else
            0.0
          end
        end

        %w[conversion value share actual_conversion].each do |method|
          define_method "#{carrier}_#{side}_#{method}" do
            slot = self.converter.send(side, carrier_key)
            value = slot && slot.send(method)
            value || 0.0
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

  #
  #
  def method_missing(method_id, *arguments)
    ActiveSupport::Notifications.instrument("gql.debug", "ConverterApi:method_missing #{method_id}")

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

