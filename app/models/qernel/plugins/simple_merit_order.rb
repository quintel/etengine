module Qernel::Plugins
  # A plugin which provides access to useful Merit-related calculations, such
  # as loss-of-load and demand curves, without having to fully-run the Merit
  # order itself.
  class SimpleMeritOrder
    include Plugin

    # Simple-mode does not need a full-run, and profiles for must-runs will
    # suffice.
    PRODUCER_TYPES = [ :must_run, :volatile ].freeze

    # Public: The SimpleMeritOrder plugin is enabled only on future graphs, and
    # only when the "full" Merit order has not been requested.
    def self.enabled?(graph)
      graph.present? ||
        graph.dataset_get(:use_merit_order_demands).to_i != 1
    end

    # Public: A unique name to represent the plugin.
    #
    # Returns a symbol.
    def self.plugin_name
      :merit
    end

    # Public: Returns the Merit Order instance. The simple version of the M/O
    # plugin does not initialize the Merit::Order until it is required.
    #
    # Returns a Merit::Order.
    def order
      setup unless @order
      @order
    end

    # Internal: Sets up the Merit::Order. Depending on whether the end-user
    # wants full merit order demands, we will either set up a "light" version
    # which contains only enough information to perform "helper" calculations
    # (such as loss-of-load).
    #
    # If the user wants to include the Merit Order in their graph, we have to
    # supply additional information so that we can determine cost and
    # profitability.
    def setup
      @order = Merit::Order.new

      self.class::PRODUCER_TYPES.each do |type|
        producers(type).each do |producer|
          klass = case type
            when :dispatchable then ::Merit::DispatchableProducer
            when :volatile     then ::Merit::VolatileProducer
            when :must_run     then ::Merit::MustRunProducer
            when :flex         then flex_class(producer)
          end

          attributes = producer_attributes(type, producer.converter_api)

          @order.add(klass.new(attributes))
        end
      end

      @order.add(::Merit::User.create(
        key:               :total_demand,
        load_profile:      dataset.load_profile(:total_demand),
        total_consumption: total_demand
      ))
    end

    #######
    private
    #######

    # Public: Returns the Atlas dataset for the current graph region.
    def dataset
      @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
    end

    # Internal: Ahe total electricity demand, joules, across the graph.
    #
    # Returns a float.
    def total_demand
      0.0
    end

    # Internal: Returns an array of converters which are of the requested merit
    # order +type+ (defined in PRODUCER_TYPES).
    #
    # Returns an array.
    def producers(type)
      (Etsource::MeritOrder.new.import[type.to_s] || {}).map do |key, profile|
        converter = @graph.converter(key)
        converter.converter_api.load_profile_key = profile

        converter
      end
    end

    # Internal: Given a Merit order participant +type+ and the associated
    # Converter, +conv+, from the graph, returns a hash of attributes required
    # to set up the Participant object in the Merit order.
    #
    # Returns a hash.
    def producer_attributes(type, conv)
      output_cap = conv.electricity_output_conversion * conv.input_capacity

      attributes = {
        key:                      conv.key,
        output_capacity_per_unit: output_cap,
        number_of_units:          conv.number_of_units,
        availability:             conv.availability,

        # The marginal costs attribute is not optional, but it is an
        # unnecessary calculation when the Merit order is not being run.
        marginal_costs:           0.0
      }

      if type == :must_run || type == :volatile
        attributes[:load_profile] = dataset.load_profile(conv.load_profile_key)
        attributes[:full_load_hours] = conv.full_load_hours
      elsif type == :flex
        # attributes[:volume] = 10.0
        attributes.merge!(flex_attributes(conv))
      end

      attributes
    end

    # Internal: Extracts from a converter values which are required for the
    # correct calculation of flexible technologies in the merit order.
    #
    # Returns a hash.
    def flex_attributes(_conv)
      {}
    end

    # Internal Given a converter representing a flexible technology, returns
    # the correct Merit class to represent it in the merit order.
    #
    # Returns a Merit::Participant.
    def flex_class(producer)
      case producer.converter_api.load_profile_key.to_sym
        when :power_to_power, :power_to_heat, :electric_vehicle
          ::Merit::Flex::Storage
        when :power_to_gas, :export
          ::Merit::Flex::BlackHole
        else
          ::Merit::Flex::Base
      end
    end
  end # SimpleMeritOrder
end # Qernel::Plugins
