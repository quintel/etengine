module Api
  module V3
    # Presents information about the inputs and outputs of converters.
    class ConverterFlowPresenter
      # Creates a new converter flow presenter.
      #
      # scenario - The Scenario whose converter details are to be presented.
      #
      # Returns an ConverterFlowPresenter.
      def initialize(scenario)
        @graph = scenario.gql.future.graph
      end

      # Public: Formats the converters for the scenario as a CSV file
      # containing the data.
      #
      # Returns a String.
      def as_csv(*)
        CSV.generate do |csv|
          csv << attributes
          converters.each { |converter| csv << converter_row(converter) }
        end
      end

      private

      def attributes
        @attrs ||= ['key'] + (%w[input_of output_of].flat_map do |prefix|
          @graph.carriers.map { |c| "#{ prefix }_#{ c.key }" }
        end)
      end

      def converters
        @graph.converters.sort_by(&:key).map(&:query)
      end

      # Internal: Creates an array/CSV row representing the converter and its
      # demands.
      def converter_row(converter)
        attributes.map { |attr| converter.try(attr) || 0.0 }
      end
    end
  end
end
