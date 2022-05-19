# frozen_string_literal: true

module Etsource
  module Config
    module_function

    # Public: Inputs whose unit should not be scaled for small scenarios and
    # regions.
    #
    # Returns an array of strings.
    def unscaleable_units
      read(:unscaleable_units)
    end

    # Public: Defines the layers in the electricity network.
    #
    # Returns an array of hashes containing the name of the layer and the means
    # by which the peak load is determined.
    def electricity_network
      read(:electricity_network).map do |layer|
        { name: layer['name'].to_sym, peak: layer['peak'].classify }
      end
    end

    # Public: Fetches the profile names used to build a dynamic curve. Raises
    # KeyError if no such dynamic curve exists.
    #
    # Returns an array of strings.
    def dynamic_curve(name)
      read(:dynamic_curves).fetch(name.to_s)
    end

    # Public: Fetches the list of Fever groups, in the order in which they
    # should be calculated.
    def fever
      read('fever').map(&:to_sym)
    end

    # Public: Reads the order of dispatchables to be used in the heat network.
    #
    # Returns an array of strings.
    def heat_network_order
      read('heat_network_order')
    end

    # Public: Contains a configuration for the sankey CSV export.
    #
    # See ConfiguredCSVSerializer.
    #
    # Returns a hash.
    def sankey_csv
      read('sankey_csv')
    end

    # Public: Reads the hash of curves for which users may upload a custom curve.
    #
    # Returns a Hash of {String => CurveHandler::Config}.
    def user_curves
      NastyCache.instance.fetch('etsource.config.user_curves_objects') do
        Hash[
          read('user_curves').map do |key, config|
            [key, CurveHandler::Config.from_etsource(config.deep_symbolize_keys.merge(key: key))]
          end
        ]
      end
    end

    private_class_method def read(name)
      NastyCache.instance.fetch("etsource.config.#{name}") do
        IceNine.deep_freeze(Atlas::Config.read(name))
      end
    end
  end
end
