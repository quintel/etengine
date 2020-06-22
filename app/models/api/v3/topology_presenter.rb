module Api
  module V3
    class TopologyPresenter

      def initialize(scenario)
        @scenario = scenario
        @gql = @scenario.gql(prepare: true)
        @nodes = @gql.present_graph.nodes
      end

      # Creates a Hash suitable for conversion to JSON by Rails.
      #
      # @return [Hash{Symbol=>Object}]
      #   The Hash containing the scenario attributes.
      #
      def as_json(*)
        json = Hash.new
        json[:nodes] = nodes
        json[:links] = links
        json
      end

      #######
      private
      #######

      def nodes
        @nodes.map do |c|
          position = positions.find(c)

          {
            key:               c.key,
            x:                 position[:x],
            y:                 position[:y],
            fill_color:        NodePositions::FILL_COLORS[c.sector_key],
            stroke_color:      '#999',
            sector:            c.sector_key,
            use:               c.use_key
          }

        end
      end

      def links
        @nodes.map(&:input_links).flatten.uniq.map do |l|
          {
            left: l.lft_node.key,
            right: l.rgt_node.key,
            color: l.carrier.graphviz_color || '#999',
            type: l.link_type
          }
        end
      end

      def positions
        NodePositions.new(Atlas.data_dir.join('config/node_positions.yml'))
      end
    end
  end
end
