module Api
  module V3
    # Presents information about the inputs and outputs of nodes.
    class NodeFlowPresenter
      # Creates a new node flow presenter.
      #
      # scenario - The Scenario whose node details are to be presented.
      #
      # Returns an NodeFlowPresenter.
      def initialize(scenario)
        @graph = scenario.gql.future.graph
      end

      # Public: Formats the nodes for the scenario as a CSV file
      # containing the data.
      #
      # Returns a String.
      def as_csv(*)
        CSV.generate do |csv|
          csv << attributes
          nodes.each { |node| csv << node_row(node) }
        end
      end

      private

      def attributes
        @attrs ||= ['key'] + (%w[input_of output_of].flat_map do |prefix|
          @graph.carriers.map { |c| "#{ prefix }_#{ c.key }" }
        end)
      end

      def nodes
        @graph.nodes.sort_by(&:key).map(&:query)
      end

      # Internal: Creates an array/CSV row representing the node and its
      # demands.
      def node_row(node)
        attributes.map { |attr| node.try(attr) || 0.0 }
      end
    end
  end
end
