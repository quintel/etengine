module Api
  module V3
    class TopologyPresenter

      # converter groups that have the converter summary table
      GROUPS_WITH_EXTRA_INFO = [
        :cost_traditional_heat,
        :cost_electricity_production,
        :cost_heat_pumps,
        :cost_chps,
        :cost_carbon_capturing,
        :cost_p2g,
        :cost_p2h
      ]

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
            use:               c.use_key,
            summary_available: (c.groups & GROUPS_WITH_EXTRA_INFO).any?
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
        ConverterPositions.new(
          Rails.root.join('config/converter_positions.yml'))
      end
    end
  end
end
