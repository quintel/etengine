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

    def initialize
      @etsource = Etsource::Base.instance
      @datasets = {}.with_indifferent_access
      @gquery = Gqueries.new(@etsource)
    end

    # @return [Qernel::Graph] a deep clone of the graph.
    #   It is important to work with clones, because present and future_graph should
    #   be independent to reduce bugs.
    def graph
      Marshal.load(Marshal.dump(optimized_graph))
    end

    # @return [Qernel::Dataset] Dataset to be used for a country. Is in a uncalculated state.
    def dataset(country)
      ActiveSupport::Notifications.instrument("etsource.performance.dataset(#{country.inspect}") do
        if @etsource.cache_dataset?
          # DEBT Limitations of this cache:
          # if experimenting with input tool, you change a transformer.yml or config.yml will not
          # take effect, because cache only invalidates when a research dataset has been changed 
          # or updated.
          cache("datasets/#{country}/#{InputTool::SavedWizard.last_updated(country).to_i}") do
            ::Etsource::Dataset.new(country).import
          end
        else
          ::Etsource::Dataset.new(country).import
        end
      end
    end

    def gqueries
      cache("gqueries") do
        @gquery.gqueries
      end
    end

    def gquery_groups
      cache("gqueries") do
        @gquery.gquery_groups
      end
    end

    def inputs
      cache("inputs") do

      end
    end

  protected

    def cache(key, &block)
      Rails.cache.fetch(cache_key+key) do
        yield
      end
    end

    def cache_key
      filename = @etsource.base_dir + '/tmp/restart.txt'
      restart_touched_at = File.exists?(filename) ? File.ctime(filename).to_i : 'none'
      "#{restart_touched_at}/etsource/#{@etsource.current_commit_id}/"
    end

    # A Qernel::Graph from ETsource where the converters are ordered in a way that
    #  is optimal for the calculation. 
    #
    def optimized_graph
      ActiveSupport::Notifications.instrument("etsource.performance.optimized_graph") do
        @optimized_graph ||= Rails.cache.fetch("etsource/#{@etsource.current_commit_id}/optimized_graph") do
          g = unoptimized_graph
          g.dataset = dataset('nl')
          g.optimize_calculation_order
          g.reset_dataset!
          g
        end
      end
    end

    def unoptimized_graph
      @graph ||= Etsource::Topology.new.import
    end
  end
end