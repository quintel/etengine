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
      @datasets = {}.with_indifferent_access
      @area_attributes = {}.with_indifferent_access
      @gquery = Gqueries.new(@etsource)
    end

    def globals(file_name)
      instrument("etsource.loader: globals #{file_name.inspect}") do
        cache("globals/#{file_name}") do
          f = "#{@etsource.export_dir}/datasets/_globals/#{file_name}.yml"
          File.exists?(f) ? YAML::load_file(f) : nil
        end
      end
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
      @area_attributes[area_code] ||= begin
        area_attr = Atlas::Dataset.find(area_code).to_hash
        area_attr['last_updated_at'] = @etsource.last_updated_at("datasets/#{area_code}")
        area_attr.with_indifferent_access
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

    # Only used for the gql console dataset output
    def raw_hash(country)
      ::Etsource::Dataset::Import.new(country).raw_hash
    end

    def gqueries
      instrument("etsource.loader: gqueries") do
        cache("gqueries") do
          @gquery.import
        end
      end
    end

    def inputs
      instrument("etsource.loader: inputs") do
        cache("inputs") do
          Inputs.new(@etsource).import
        end
      end
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

    # A Qernel::Graph from ETsource where the converters are ordered in a way that
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
