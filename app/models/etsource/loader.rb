module Etsource
  class Loader
    include Singleton

    def initialize
      @etsource = Etsource::Base.new
    end

    # @return [Qernel::Graph] a deep clone of the graph.
    def graph_clone
      Marshal.load(Marshal.dump(graph))
    end

    def dataset(country)
      datasets[country]
    end

  protected

    # @return {:nl => Qernel::Dataset, :uk => Qernel::Dataset} Hash of all datasets
    def datasets
      @datasets ||= Etsource::Dataset.new(@etsource).import.with_indifferent_access
    end

    # A Qernel::Graph from ETsource where the converters are ordered in a way that
    #  is optimal for the calculation. 
    #
    def optimized_graph
      unless @optimized_graph 
        g = unoptimized_graph
        g.dataset = dataset('nl')
        g.optimize_calculation_order
        g.reset_dataset!
        @optimized_graph = g
      end
      @optimized_graph
    end

    def unoptimized_graph
      @graph ||= Etsource::Graph.new(@etsource).import
    end
    
    def graph
      optimized_graph
    end  
  end
end