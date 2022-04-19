# frozen_string_literal: true

require 'forwardable'

module Qernel
  module NodeApi
    # See Qernel::NodeApi.

    # A basic implementation of NodeApi. See Qernel::NodeApi for an explanation.
    #
    # Methods should generally not be defined directly on Base unless you're absolutely certain that
    # they should override any methods defined in any of the used modules. In the past, some methods
    # would be defined directly on the calss (such as `input_of_loss`, now part of `CarrierMethods`)
    # which would override the custom implementation in `DemandSupply`.
    #
    # Instead, define methods in a module and include the module into the class.
    class Base
      extend Forwardable
      extend DatasetCurveAttributes

      include MethodMetaData
      include DatasetAttributes
      include Attributes

      # Carrier methods must be among the first included modules, as later modules may make further
      # customisations.
      include CarrierMethods

      include CapacityProduction
      include Conversion
      include Cost
      include DemandHelpers
      include DemandSupply
      include Employment
      include HelperCalculations
      include FallbackMethods

      include RecursiveFactor::Base
      include RecursiveFactor::WeightedCarrier
      include RecursiveFactor::MaxDemand

      # attributes updated by #initialize
      attr_reader :node, :dataset_group, :dataset_key

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

      # Curves which may be set by an external source.
      dataset_curve_accessor :availability_curve
      dataset_curve_accessor :marginal_cost_curve

      # Curves set by Causality.
      dataset_curve_reader :curtailment_output_curve
      dataset_curve_reader :storage_curve

      dataset_carrier_curve_reader :electricity
      dataset_carrier_curve_reader :hydrogen
      dataset_carrier_curve_reader :heat
      dataset_carrier_curve_reader :network_gas
      dataset_carrier_curve_reader :steam_hot_water

      alias_method :useable_heat_output_curve, :heat_output_curve
      alias_method :useable_heat_input_curve,  :heat_input_curve

      alias_method :steam_hot_water_output_capacity, :heat_output_capacity
      alias_method :useable_heat_output_capacity, :heat_output_capacity

      def_delegators(
        :@node,
        :abroad?,
        :bio_resources_demand?,
        :energy_import_export?,
        :final_demand_group?,
        :input,
        :input_carriers,
        :input_edges,
        :inputs,
        :key,
        :lft_edges,
        :non_energetic_use?,
        :output,
        :output_carriers,
        :output_edges,
        :outputs,
        :preset_demand=,
        :primary_energy_demand?,
        :recursive_factor_ignore?,
        :rgt_edges,
        :slots,
        :useful_demand?
      )

      # Optimization for flatten.
      attr_reader :to_ary

      def to_s
        node && node.key.to_s
      end

      def inspect
        "#<#{self.class.name} key=#{node.key}>"
      end

      def query
        self
      end

      # For testing only
      # Otherwise graphs by GraphParser won't be Gqueryable
      # DEBT properly fix
      def_delegator(:@node, :dataset_attributes) if Rails.env.development? || Rails.env.test?

      def initialize(node_qernel, _attrs = {})
        @node = node_qernel
        @dataset_key = node.dataset_key
        @dataset_group = node.dataset_group
      end
    end
  end
end
