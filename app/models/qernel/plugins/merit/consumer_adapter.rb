module Qernel::Plugins
  module Merit
    # Converts a Qernel::Converter to a Merit user.
    class ConsumerAdapter < Adapter
      def self.factory(converter, _graph, _dataset)
        case converter.merit_order.subtype
        when :pseudo
          PseudoConsumerAdapter
        else
          self
        end
      end

      def participant
        @participant ||= ::Merit::User.create(
          key: @converter.key,
          load_profile: consumption_profile,
          total_consumption: input_of_electricity
        )
      end

      def inject!
        target_api.dataset_lazy_set(:electricity_input_curve) do
          @participant.load_curve.to_a
        end
      end

      def input_of_electricity
        if source_api.converter.input(:electricity)
          source_api.input_of_electricity
        elsif source_api.converter.input(:loss)
          # HV loss node does not have an electricity input; use graph method
          # which compensates for export.
          @graph.query.electricity_losses_if_export_is_zero
        else
          raise "No acceptable consumption input for #{source_api.key}"
        end
      end

      private

      def consumption_profile
        @graph.plugin(:merit).curves.profile(@config.group, @converter)
      end
    end
  end
end
