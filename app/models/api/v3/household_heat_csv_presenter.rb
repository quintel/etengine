module Api
  module V3
    # Creates CSV rows describing household heat demand and supply.
    class HouseholdHeatCSVPresenter
      def initialize(graph)
        @graph = graph
      end

      def to_csv_rows
        # Empty CSV if time-resolved calculations are not enabled.
        unless @graph.plugin(:time_resolve)&.fever
          return [['Merit order and time-resolved calculation are not ' \
                   'enabled for this scenario']]
        end

        [headers, *data]
      end

      private

      def headers
        [
          'Production',
          'Demand',
          'Buffering and time-shifting',
          'Deficit'
        ]
      end

      def data
        curve(:production).zip(
          curve(:demand),
          curve(:surplus),
          curve(:deficit)
        )
      end

      def curve(type)
        Qernel::Plugins::TimeResolve::Util.add_curves([
          summary(:space_heating).public_send(type),
          summary(:households_hot_water).public_send(type)
        ])
      end

      def summary(group)
        @graph.plugin(:time_resolve).fever.summary(group)
      end
    end
  end
end
