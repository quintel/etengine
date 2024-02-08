# frozen_string_literal: true

module Etsource
  module Config
    module_function

    # Public: A string identifying the key of the default dataset
    def default_dataset_key
      read(:default_dataset).to_s
    end

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
      read('fever.groups').map(&:to_sym)
    end

    # Public: Fetches the list of ordered consumers and producers for fever groups
    # in which they should be calculated
    def fever_order(group, type)
      read("fever.#{group}_#{type}_order").map(&:to_sym)
    end

    # Public: Reads the order of dispatchables to be used for hydrogen.
    #
    # Returns an array of strings.
    def hydrogen_order
      read('hydrogen_order')
    end

    # Public: Reads the order of dispatchables to be used in the heat network.
    #
    # Returns an array of strings.
    def heat_network_order_lt
      read('heat_network_order_lt')
    end

    # Public: Reads the order of dispatchables to be used in the heat network.
    #
    # Returns an array of strings.
    def heat_network_order_mt
      read('heat_network_order_mt')
    end

    # Public: Reads the order of dispatchables to be used in the heat network.
    #
    # Returns an array of strings.
    def heat_network_order_ht
      read('heat_network_order_ht')
    end

    # Public: Reads the order of storage in when forecasting is enabled.
    #
    # Returns an array of strings.
    def forecast_storage_order
      read('forecast_storage_order')
    end

    # Public: Contains a configuration for the sankey CSV export.
    #
    # See ConfiguredCSVSerializer.
    #
    # Returns a hash.
    def sankey_csv
      read('sankey_csv')
    end

    # Public: Contains a configuration for the storage parameters CSV export.
    #
    # See ConfiguredCSVSerializer.
    #
    # Returns a hash.
    def storage_parameters_csv
      read('storage_parameters_csv')
    end


    # Public: Contains a configuration for the residual load CSV export.
    #
    # Returns an array of hashes.
    def residual_load_csv
      read('residual_load_csv').map(&:symbolize_keys)
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
