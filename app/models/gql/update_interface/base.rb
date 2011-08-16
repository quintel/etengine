module Gql

module UpdateInterface

  class Base
    include UpdatingConverter
    include Selecting

    attr_reader :graph

    def initialize(graph)
      @graph_model = graph_model
      @present_graph = present_graph
      @future_graph = future_graph
    end

    # Updates and calculates the graphs
    #
    def prepare_graphs
      Rails.logger.warn("*** GQL#prepare_graphs")

      # 2011-08-15: the present has to be updated 
      # otherwise updating the future won't work (we need the present values :-)
      update_present_graph_from_cache

      apply_updates(future_graph)
      calculate_graph(future_graph)

      apply_policy_updates

      # At this point the gql is calculated. Changes through update statements
      # should no longer be allowed, as they won't have an impact on the 
      # calculation (even though updating prices would work).
      @calculated = true

      after_calculation_updates(present_graph)
      after_calculation_updates(future_graph)
    end


    def update_present_graph_from_cache
      present_graph.dataset = graph_model.calculated_present_data
    end

    def apply_policy_updates
      update_statements = Current.scenario.update_statements
      update_policies(update_statements['policies']) if update_statements
    end

    def apply_updates(graph)
      update_statements = Current.scenario.update_statements

      graph.dataset = graph_model.dataset.to_qernel

      if update_statements
        update_time_curves(graph)
        update_carriers(   graph, update_statements['carriers'])
        update_area_data(  graph, update_statements['area'])
        update_converters( graph, update_statements['converters'])
      end
    end

    def calculate_graph(graph)
      benchmark("calculate #{graph.year}") do
        graph.calculate
      end
    end
  end
  
end

end
  