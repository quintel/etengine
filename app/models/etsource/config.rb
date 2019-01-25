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

    private_class_method def read(name)
      NastyCache.instance.fetch("etsource.config.#{name}") do
        IceNine.deep_freeze(Atlas::Config.read(name))
      end
    end
  end
end
