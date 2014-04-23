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
  include CalculationUnits

  def self.dataset_group; :graph; end

  ##
  # :method: primary_demand_of_fossil
  # Primary demand of fossil energy

  EXPECTED_DEMAND_TOLERANCE = 0.001


  # attributes updated by #initialize
  attr_reader :converter, :dataset_key, :dataset_group
  # attributes updated by Converter#graph=
  attr_accessor :area, :graph

  # attribute used by merit order
  attr_accessor :load_profile_key

  # dataset attributes of converter
  dataset_accessors [:preset_demand, :demand]

  # Returns a ConverterApi instance based on the given Converter.
  #
  # Most converters will get a ConverterApi, but for some it makes sense to
  # get a DemandDriven API instead.
  #
  # @param [Qernel::Converter] converter
  #   A converter instance for which you want a ConverterApi.
  #
  # @return [Qernel::ConverterApi]
  #   The appropriate ConverterApi subclass for the converter.
  #
  def self.for_converter(converter)
    if converter.groups.include?(:demand_driven)
      DemandDrivenConverterApi.new(converter)
    else
      ConverterApi.new(converter)
    end
  end

  # optimization for flatten
  attr_reader :to_ary

  # ConverterApi has same accessor as it's converter
  def self.dataset_group
    @dataset_group ||= Qernel::Converter.dataset_group
  end

  def to_s
    converter && converter.key.to_s
  end

  def inspect
    to_s
  end

  # For testing only
  # Otherwise graphs by GraphParser won't be Gqueryable
  # DEBT properly fix
  if Rails.env.development? or Rails.env.test?
    def dataset_attributes
      converter.dataset_attributes
    end
  end

  def initialize(converter_qernel, attrs = {})
    @converter = converter_qernel
    @dataset_key = converter.dataset_key
    @dataset_group = converter.dataset_group
  end

  def key
    converter.key
  end

  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  def preset_demand=(val)
    converter.preset_demand = val
  end

  # Updates a (power plant) converter demand by its electricity output.
  #
  # That means we have to divide by the conversion of the electricity slot. So
  # that the electricity output link receive that value, otherwise one part would
  # go away to losses.
  #
  # UPDATE( ... , preset_demand_by_electricity_production, 1000)
  #
  #               +--------+
  #  1000   el---o|        |
  #               |  1030  |o----
  #    30 loss---o|        |
  #               +--------+
  #
  def preset_demand_by_electricity_production=(val)
    if output_slot = converter.output(:electricity)
      converter.preset_demand = val / output_slot.conversion
    else
      raise "UPDATE: preset_demand_by_electricity_production could not find an electricity output for #{key.inspect}"
    end
  end

  def primary_demand
    self.converter.primary_demand
  end
  unit_for_calculation "primary_demand", 'MJ'


  def final_demand
    self.converter.final_demand
  end
  unit_for_calculation "final_demand", 'MJ'

  # Is the calculated near the demand_expected_value?
  #
  # @return [nil] if demand or expected is nil
  # @return [true] if demand is within tolerance EXPECTED_DEMAND_TOLERANCE
  #
  def demand_expected?
    expected = demand_expected_value

    return nil if demand.nil? or expected.nil?

    actual   = demand.round(4)
    expected = expected.round(4)

    return true if actual.to_f == 0 and expected.to_f == 0.0
    (actual.to_f / expected.to_f - 1.0).abs < EXPECTED_DEMAND_TOLERANCE
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
      unit_for_calculation "demand_of_#{carrier}", 'MJ'

      define_method "supply_of_#{carrier}" do
        self.input_of_carrier(carrier_key) || 0.0
      end
      unit_for_calculation "supply_of_#{carrier}", 'MJ'

      define_method "input_of_#{carrier}" do
        self.input_of_carrier(carrier_key) || 0.0
      end
      unit_for_calculation "input_of_#{carrier}", 'MJ'

      define_method "output_of_#{carrier}" do
        self.output_of_carrier(carrier_key) || 0.0
      end
      unit_for_calculation "output_of_#{carrier}", 'MJ'

      define_method "primary_demand_of_#{carrier}" do
        converter.primary_demand_of_carrier(carrier_key) || 0.0
      end
      unit_for_calculation "primary_demand_of_#{carrier}", 'MJ'

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
          self.class_eval <<-EOF,__FILE__,__LINE__ +1
            def #{carrier}_#{side}_#{method}
              fetch(:#{carrier}_#{side}_#{method}) do
                slot = self.converter.#{side}(#{carrier_key.inspect})
                value = slot && slot.send(#{method.inspect})
                value || 0.0
              end
            end
          EOF
          # define_method "#{carrier}_#{side}_#{method}" do
          #   slot = self.converter.send(side, carrier_key)
          #   value = slot && slot.send(method)
          #   value || 0.0
          # end
        end
      end
    end
  end
  create_methods_for_each_carrier(Etsource::Dataset::Import.new('nl').carrier_keys)

  # creates a method during run time if method_missing
  #
  def self.create_share_of_converter_method(converter_key)
    key = converter_key.to_sym
    define_method "share_of_#{key}" do
      ol = self.converter.output_links.detect{|l| l.lft_converter.key == key}
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

  def method_missing(method_id, *arguments)
    ActiveSupport::Notifications.instrument("gql.debug", "ConverterApi:method_missing #{method_id}")

    # electricity_
    if m = /^(.*)_(input|output)_link_(share|value)$/.match(method_id.to_s)
      carrier_name, side, method = m.captures
      self.class.create_input_link_method_and_execute(self, method_id, carrier_name, side, method)
    elsif m = /^share_of_(\w*)$/.match(method_id.to_s) and match = m.captures.first
      self.class.create_share_of_converter_method_and_execute(self, match)
    elsif m = /^cost_(\w*)$/.match(method_id.to_s) and method_name = m.captures.first
      self.send(method_name)
    elsif m = /^primary_demand(\w*)$/.match(method_id.to_s)
      self.converter.send(method_id, *arguments)
    elsif m = /^dependent_supply(\w*)$/.match(method_id.to_s)
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
