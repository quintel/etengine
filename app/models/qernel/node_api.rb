# frozen_string_literal: true

module Qernel
  ##
  # == Big Picture
  #
  # === Node
  # Responsible for calculating demands/energy flow only. Has edges and
  # slots, so can traverse the graph. But doesn't know about its other
  # attributes like cost, co2, etc. It is more like a node in a graph.
  #
  # === NodeApi
  #
  # A NodeApi instance includes (static) attributes (stored in the
  # ::Node table) and dynamic attributes that are calculated based
  # on the static ones. It doesn't (really) know about edges, slots, etc
  # but can access them through #node. It's more like a data-model.
  #
  #
  # === Reasons for separation
  #
  # Node is relatively simple, NodeApi has a lot of code. Like
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
  class NodeApi
    extend DatasetCurveAttributes

    include MethodMetaData
    include DatasetAttributes
    include CalculationUnits

    # Include parts after attribute accessors have been defined; methods defined in the moduels
    # should override those defined above.
    prepend Attributes
    prepend CapacityProduction
    prepend Conversion
    prepend Cost
    prepend DemandSupply
    prepend Employment
    prepend HelperCalculations
    prepend RecursiveMethods

    EXPECTED_DEMAND_TOLERANCE = 0.001

    # attributes updated by #initialize
    attr_reader :node, :dataset_key

    # attributes updated by Node#graph=
    attr_accessor :area, :graph

    # attribute used by merit order
    attr_accessor :load_profile_key

    dataset_accessors Attributes::ATTRIBUTES_USED

    # dataset attributes of node
    dataset_accessors %i[
      demand
      fever
      heat_network
      hydrogen
      merit_order
      network_gas
      preset_demand
      storage
    ]

    dataset_curve_reader :curtailment_output_curve
    dataset_curve_reader :marginal_cost_curve
    dataset_curve_reader :storage_curve
    dataset_carrier_curve_reader :electricity
    dataset_carrier_curve_reader :hydrogen
    dataset_carrier_curve_reader :heat
    dataset_carrier_curve_reader :network_gas
    dataset_carrier_curve_reader :steam_hot_water

    alias_method :useable_heat_output_curve, :heat_output_curve
    alias_method :useable_heat_input_curve,  :heat_input_curve

    def marginal_cost_curve=(curve)
      # Ignore empty curves and set no value.
      dataset_set(:marginal_cost_curve, curve&.any? ? curve : nil)
    end

    alias_method :steam_hot_water_output_capacity, :heat_output_capacity
    alias_method :useable_heat_output_capacity, :heat_output_capacity

    # Returns a NodeApi instance based on the given Node.
    #
    # Most nodes will get a NodeApi, but for some it makes sense to
    # get a DemandDriven API instead.
    #
    # @param [Qernel::Node] node
    #   A node instance for which you want a NodeApi.
    #
    # @return [Qernel::NodeApi]
    #   The appropriate NodeApi subclass for the node.
    #
    def self.for_node(node)
      if node.groups.include?(:demand_driven)
        DemandDrivenNodeApi.new(node)
      elsif node.groups.include?(:inheritable_nou)
        InheritableNouNodeApi.new(node)
      else
        NodeApi.new(node)
      end
    end

    # Optimization for flatten.
    attr_reader :to_ary

    # NodeApi has same accessor as its node
    def self.dataset_group
      @dataset_group ||= Qernel::Node.dataset_group
    end

    def to_s
      node && node.key.to_s
    end

    def inspect
      to_s
    end

    # For testing only
    # Otherwise graphs by GraphParser won't be Gqueryable
    # DEBT properly fix
    delegate(:dataset_attributes, to: :node) if Rails.env.development? || Rails.env.test?

    def initialize(node_qernel, _attrs = {})
      @node = node_qernel
      @dataset_key = node.dataset_key
      @dataset_group = node.dataset_group
    end

    delegate :key, to: :node

    # See {Qernel::Node} for difference of demand/preset_demand
    delegate :preset_demand=, to: :node

    # Updates a (power plant) node demand by its electricity output.
    #
    # That means we have to divide by the conversion of the electricity slot. So
    # that the electricity output edge receive that value, otherwise one part would
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
      output_slot = node.output(:electricity)

      unless output_slot
        raise 'UPDATE: preset_demand_by_electricity_production could not find an electricity ' \
              "output for #{key.inspect}"
      end

      node.preset_demand = val / output_slot.conversion
    end

    # Updates a (hydrogen production plant) node demand by its hydrogen output.
    #
    # That means we have to divide by the conversion of the hydrogen slot. So
    # that the hydrogen output edge receive that value, otherwise one part would
    # go away to losses.
    #
    # UPDATE( ... , preset_demand_by_hydrogen_production, 1000)
    #
    #                   +--------+
    #  1000 hydrogen---o|        |
    #                   |  1030  |o----
    #    30 loss-------o|        |
    #                   +--------+
    #
    def preset_demand_by_hydrogen_production=(val)
      output_slot = node.output(:hydrogen)

      unless output_slot
        raise 'UPDATE: preset_demand_by_hydrogen_production could not find an hydrogen output ' \
              "for #{key.inspect}"
      end

      node.preset_demand = val / output_slot.conversion
    end

    delegate :primary_demand, to: :node
    unit_for_calculation 'primary_demand', 'MJ'

    delegate :final_demand, to: :node
    unit_for_calculation 'final_demand', 'MJ'

    # Is the calculated near the demand_expected_value?
    #
    # Returns nil if demand or expected is nil. Returns true if demand is within tolerance
    # EXPECTED_DEMAND_TOLERANCE.
    def demand_expected?
      expected = demand_expected_value

      return nil if demand.nil? || expected.nil?

      actual   = demand.round(4)
      expected = expected.round(4)

      return true if actual.to_f.zero? && expected.to_f.zero?

      (actual.to_f / expected - 1.0).abs < EXPECTED_DEMAND_TOLERANCE
    end

    # Extracted into a method, because we have a circular dependency in specs
    # Carriers are not imported, so when initializing all those methods won't get
    # loaded. So this way we can load later.
    def self.create_methods_for_each_carrier(carrier_names)
      carrier_names.each do |carrier|
        carrier_key = carrier.to_sym
        define_method "demand_of_#{carrier}" do
          output_of_carrier(carrier_key) || 0.0
        end
        unit_for_calculation "demand_of_#{carrier}", 'MJ'

        define_method "supply_of_#{carrier}" do
          input_of_carrier(carrier_key) || 0.0
        end
        unit_for_calculation "supply_of_#{carrier}", 'MJ'

        define_method "input_of_#{carrier}" do
          input_of_carrier(carrier_key) || 0.0
        end
        unit_for_calculation "input_of_#{carrier}", 'MJ'

        define_method "output_of_#{carrier}" do
          output_of_carrier(carrier_key) || 0.0
        end
        unit_for_calculation "output_of_#{carrier}", 'MJ'

        define_method "primary_demand_of_#{carrier}" do
          node.primary_demand_of_carrier(carrier_key) || 0.0
        end
        unit_for_calculation "primary_demand_of_#{carrier}", 'MJ'

        %w[input output].each do |side|
          define_method "#{carrier}_#{side}_edge_share" do
            if (slot = node.send(side, carrier_key))
              if (edge = slot.edges.first)
                edge.send('share') || 0.0
              else
                0.0
              end
            else
              0.0
            end
          end

          %w[conversion value share actual_conversion].each do |method|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{carrier}_#{side}_#{method}
                fetch(:#{carrier}_#{side}_#{method}) do
                  slot = self.node.#{side}(#{carrier_key.inspect})
                  value = slot && slot.send(#{method.inspect})
                  value || 0.0
                end
              end
            RUBY
          end
        end
      end
    end
    create_methods_for_each_carrier(Etsource::Dataset::Import.new('nl').carrier_keys)

    # Creates a method during run time if method_missing
    def self.create_share_of_node_method(node_key)
      key = node_key.to_sym
      define_method "share_of_#{key}" do
        ol = node.output_edges.detect { |l| l.lft_node.key == key }
        ol&.share
      end
    end

    # Creates a method during run time if method_missing and returns the value.
    def self.create_share_of_node_method_and_execute(caller, node_key)
      create_share_of_node_method(node_key)
      caller.send("share_of_#{node_key}")
    end

    # Creates a method during run time if method_missing.
    def self.create_input_edge_method(method_id, carrier_name, side, method)
      if /^(.*)_(constant|share|inversedflexible|flexible)$/.match?(carrier_name)
        carrier_name, edge_type =
          carrier_name.match(/^(.*)_(constant|share|inversedflexible|flexible)$/).captures

        edge_type = 'inversed_flexible' if edge_type == 'inversedflexible'
      end
      define_method method_id do
        if (slot = node.send(side, carrier_name.to_sym))
          edge = if edge_type.nil?
            slot.edges.first
          else
            slot.edges.detect { |l| l.send("#{edge_type}?") }
          end

          edge&.send(method)
        end
      end
    end

    # Creates a method during run time if method_missing and returns the value
    def self.create_input_edge_method_and_execute(caller, method_id, carrier_name, side, method)
      create_input_edge_method(method_id, carrier_name, side, method)
      caller.send(method_id)
    end

    def method_missing(method_id, *arguments)
      ActiveSupport::Notifications.instrument('gql.debug', "NodeApi:method_missing #{method_id}")

      method_id_s = method_id.to_s

      # electricity_
      if (m = /^(.*)_(input|output)_edge_(share|value)$/.match(method_id_s))
        carrier_name, side, method = m.captures
        self.class.create_input_edge_method_and_execute(self, method_id, carrier_name, side, method)
      elsif (m = /^share_of_(\w*)$/.match(method_id_s)) && (match = m.captures.first)
        self.class.create_share_of_node_method_and_execute(self, match)
      elsif (m = /^cost_(\w*)$/.match(method_id_s)) && (method_name = m.captures.first)
        send(method_name)
      elsif /^primary_demand(\w*)$/.match?(method_id_s)
        node.send(method_id, *arguments)
      elsif /^demand_of_(\w*)$/.match?(method_id_s)
        node.send(method_id, *arguments)
      elsif /^dependent_supply(\w*)$/.match?(method_id_s)
        node.send(method_id, *arguments)
      elsif /^final_demand(\w*)$/.match?(method_id_s)
        node.send(method_id, *arguments)
      else
        Rails.logger.info("NodeApi#method_missing: #{method_id}")
        super(method_id)
      end
    end
  end
end
