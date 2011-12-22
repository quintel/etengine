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
      @etsource = Etsource::Base.new
      @datasets = {}.with_indifferent_access
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
        # @datasets[country] ||= 
        Rails.cache.fetch(dataset_cache_key(country)) do
          ::Etsource::Dataset.new(country).import
        end
      end
    end


  protected
    def dataset_cache_key(country)
      etsource_tmp_restart_touched_at = File.ctime(@etsource.base_dir + '/tmp/restart.txt').to_i
      k = "#{etsource_tmp_restart_touched_at}/etsource/#{@etsource.current_commit_id}/datasets/#{country}/#{InputTool::Form.last_updated(country).to_i}"
      Rails.logger.warn(k)
      k
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
      @graph ||= Etsource::Topology.new(@etsource).import
    end
  end
end