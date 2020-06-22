# Loader is an interface to the ETsource. It takes care of loading and caching
# of ETsource components.
#
#     loader = Etsource::Loader.instance
#     # load the (one&only) graph
#     graph = loader.graph
#     # next attach the dutch dataset to the graph
#     graph.dataset = loader.dataset('nl')
#
module Etsource
  class Loader
    include Singleton
    include Instrumentable

    def initialize
      @etsource = Etsource::Base.instance
    end

    # @return [Qernel::Graph] a deep clone of the graph.
    #   It is important to work with clones, because present and future_graph should
    #   be independent to reduce bugs.
    def graph(country = nil)
      instrument("etsource.loader: graph") do
        graph = DeepClone.clone optimized_graph
        graph.dataset = dataset(country) if country
        graph
      end
    end

    # @return [Array<Preset>] Scenario Presets
    def presets
      Etsource::Scenario.new.presets
    end

    def area_attributes(area_code)
      cache("area_attributes/#{area_code}") do
        area = Atlas::Dataset.find(area_code)
        area_attr = area.to_hash
        area_attr[:derived] = area.is_a?(Atlas::Dataset::Derived)
        area_attr['last_updated_at'] = @etsource.last_updated_at("datasets/#{area_code}")

        IceNine.deep_freeze!(area_attr.with_indifferent_access)
      end
    end

    # @return [Qernel::Dataset] Dataset to be used for a country. Is in a uncalculated state.
    def dataset(country)
      instrument("etsource.loader: dataset(#{country.inspect})") do
        cache("datasets/#{country}") do
          ::Etsource::Dataset.new(country).import
        end
      end
    end

    # Initializes a Qernel::Dataset with the given data. Used to speed up code
    # reloading in development mode.
    def warm_dataset_with_data(country, data)
      return unless Rails.env.development?

      cache("datasets/#{country}") do
        ::Etsource::Dataset::Import.new(country).import_data(data)
      end
    end

    def gqueries
      instrument("etsource.loader: gqueries") do
        cache("gqueries") do
          Gqueries.new(@etsource).import
        end
      end
    end

    def inputs
      instrument("etsource.loader: inputs") do
        cache("inputs") do
          Inputs.new(@etsource, Atlas::Input, Input).import
        end
      end
    end

    def initializer_inputs
      instrument("etsource.loader: initializer_inputs") do
        cache("initializer_inputs") do
          Inputs.new(@etsource, Atlas::InitializerInput, InitializerInput).import
        end
      end
    end

    def clear!(type)
      Rails.cache.delete("#{cache_key}#{type}")
    end

    protected

    def cache(key, &block)
      Rails.cache.fetch(cache_key+key) do
        yield
      end
    end

    def cache_key
      "etsource/#{NastyCache.instance.local_timestamp}/"
    end

    # A Qernel::Graph from ETsource where the nodes are ordered in a way that
    #  is optimal for the calculation.
    #
    def optimized_graph
      instrument("etsource.loader: optimized_graph") do
        if @etsource.cache_topology?
          NastyCache.instance.fetch_cached("optimized_graph") do
            graph = unoptimized_graph
            graph.dataset = dataset('nl')

            merit = graph.area.dataset_get(:use_merit_order_demands)

            begin
              graph.area.dataset_set(:use_merit_order_demands, false)
              graph.optimize_calculation_order
            ensure
              graph.area.dataset_set(:use_merit_order_demands, merit)
            end

            graph.detach_dataset!
            graph
          end
        else
          unoptimized_graph
        end
      end
    end

    def unoptimized_graph
      if @etsource.cache_topology?
        NastyCache.instance.fetch_cached("unoptimized_graph") do
          Etsource::Topology.new.import
        end
      else
        Etsource::Topology.new.import
      end
    end
  end
end
