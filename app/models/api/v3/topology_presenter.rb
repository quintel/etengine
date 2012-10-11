module Api
  module V3
    class TopologyPresenter
      def initialize(scenario)
        @scenario = scenario
        @gql = @scenario.gql(prepare: true)
        @converters = @gql.present_graph.converters
        @positions = {}
        ConverterPosition.not_hidden.where("converter_key IS NOT NULL").
          each {|c| @positions[c.converter_id] = c}
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

      private

      def converters
        @converters.map do |c|
          # I'd rather use the converter key
          excel_id = c.excel_id.to_i
          position = @positions[excel_id]
          {
            key: c.key,
            x: position.try(:x) || 100,
            y: position.try(:y_or_default, c),
            fill_color: position.try(:fill_color, c),
            stroke_color: position.try(:stroke_color, c),
            sector: c.sector_key,
            use: c.use_key,
            group: c.energy_balance_group
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
    end
  end
end