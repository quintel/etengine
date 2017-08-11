module Api
  module V3
    # Presents the primary and final demands of application_group converters
    # as a CSV file.
    class ApplicationDemandsPresenter
      attr_reader :final_carriers, :primary_carriers

      # Creates a new application demands presenter.
      #
      # scenario - The Scenario whose converter demands are to be presented.
      #
      # Returns an ApplicationDemandsPresenter.
      def initialize(scenario)
        @graph = scenario.gql.future.graph
      end

      # Public: Formats the converters for the scenario as a CSV file containing
      # the data.
      #
      # Returns a String.
      def as_csv(*)
        populate_carriers!

        CSV.generate do |csv|
          csv << [
            'key', 'primary_co2_emission',
            *primary_carriers.map { |c| "primary_demand_of_#{ c }" },
            *final_carriers.map { |c| "final_demand_of_#{ c }" }
          ]

          @graph.group_converters(:application_group).each do |converter|
            csv << converter_row(converter)
          end
        end
      end

      private

      # Internal: Creates an array/CSV row representing the converter and its
      # demands.
      def converter_row(converter)
        [
          converter.key,
          converter.primary_co2_emission,
          *primary_carriers.map { |ca| converter.primary_demand_of(ca) },
          *final_carriers.map { |ca| converter.final_demand_of(ca) }
        ]
      end

      # Internal: Determines those carriers which may have a non-zero primary
      # or final demand, so as not to waste time calculating values which will
      # always be zero.
      def populate_carriers!
        primary_carriers = Set.new
        final_carriers   = Set.new

        @graph.converters.each do |conv|
          if conv.right_dead_end? || conv.primary_energy_demand?
            primary_carriers.merge(conv.outputs.map { |c| c.carrier.key })
          end

          if conv.final_demand_group?
            final_carriers.merge(conv.outputs.map { |c| c.carrier.key })
          end
        end

        @primary_carriers = primary_carriers.to_a.sort
        @final_carriers = final_carriers.to_a.sort
      end
    end
  end
end
