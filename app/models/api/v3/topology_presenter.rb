module Api
  module V3
    class TopologyPresenter

      def initialize(scenario)
        @scenario = scenario
        @gql = @scenario.gql(prepare: true)
        @converters = @gql.present_graph.converters
      end

      # Creates a Hash suitable for conversion to JSON by Rails.
      #
      # @return [Hash{Symbol=>Object}]
      #   The Hash containing the scenario attributes.
      #
      def as_json(*)
        json = Hash.new
        json[:converters] = converters
        json[:links] = links
        json
      end

      #######
      private
      #######

      def converters
        @converters.map do |c|
          position = positions.find(c)

          {
            key:               c.key,
            x:                 position[:x],
            y:                 position[:y],
            fill_color:        ConverterPositions::FILL_COLORS[c.sector_key],
            stroke_color:      '#999',
            sector:            c.sector_key,
            use:               c.use_key
          }

        end
      end

      def links
        @converters.map(&:input_links).flatten.uniq.map do |l|
          {
            left: l.lft_converter.key,
            right: l.rgt_converter.key,
            color: l.carrier.graphviz_color || '#999',
            type: l.link_type
          }
        end
      end

      def positions
        ConverterPositions.new(Atlas.data_dir.join('config/node_positions.yml'))
      end
    end
  end
end
