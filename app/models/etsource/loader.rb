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
      @gquery = Gqueries.new(@etsource)
    end

    def globals(file_name)
      instrument("etsource.loader: globals #{file_name.inspect}") do
        cache("globals/#{file_name}") do
          f = "#{@etsource.base_dir}/datasets/_globals/#{file_name}.yml"
          File.exists?(f) ? YAML::load_file(f) : nil
        end
      end
    end

    # @return [Qernel::Graph] a deep clone of the graph.
    #   It is important to work with clones, because present and future_graph should
    #   be independent to reduce bugs.
    def graph(country = nil)
      instrument("etsource.loader: graph") do
        graph = Marshal.load(Marshal.dump(optimized_graph))
        graph.dataset = dataset(country) if country
        graph
      end
    end

    # @return [Array<Preset>] Scenario Presets
    def presets
      Etsource::Scenario.new.presets
    end

    # @return [Qernel::Dataset] Dataset to be used for a country. Is in a uncalculated state.
    def dataset(country)
      instrument("etsource.loader: dataset(#{country.inspect})") do
        if @etsource.cache_dataset?
          # DEBT Limitations of this cache:
          # if experimenting with input tool, you change a transformer.yml or config.yml will not
          # take effect, because cache only invalidates when a research dataset has been changed
          # or updated.
          cache("datasets/#{country}") do
            ::Etsource::Dataset.new(country).import
          end
        else
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
          @gquery.gqueries
        end
      end
    end

    def gquery_groups
      instrument("etsource.loader: gquery_groups") do
        cache("gqueries") do
          @gquery.gquery_groups
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

    def merit_order_table
      # make sure we don't accidentally overwrite values, so we freeze everything.
      instrument("etsource.loader: merit_order_table") do
        cache("merit_order_rows") do
          rows = CSV.read("#{@etsource.base_dir}/datasets/_globals/merit_order.csv", :converters => :numeric)
          rows.map! { |row| [row.delete_at(0), row.freeze].freeze }
          rows
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
      "etsource/#{@etsource.get_latest_import_sha}/"
    end

    # A Qernel::Graph from ETsource where the converters are ordered in a way that
    #  is optimal for the calculation.
    #
    def optimized_graph
      instrument("etsource.loader: optimized_graph") do
        if @etsource.cache_topology?
          @optimized_graph ||= Rails.cache.fetch("etsource/#{@etsource.get_latest_import_sha}/optimized_graph") do
            g = unoptimized_graph
            g.dataset = dataset('nl')
            g.optimize_calculation_order
            g.reset_dataset!
            g
          end
        else
          unoptimized_graph
        end
      end
    end

    def unoptimized_graph
      if @etsource.cache_topology?
        @graph ||= Etsource::Topology.new.import
      else
        Etsource::Topology.new.import
      end
    end
  end
end
