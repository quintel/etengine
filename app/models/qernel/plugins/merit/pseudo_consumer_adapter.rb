module Qernel::Plugins
  module Merit
    # An adapter which reads a demand curve from the Merit plugin's Curve
    # object, and uses this curve as the participant demand in Merit.
    #
    # For example, another module (such as Fever) may write an electricity
    # demand curve
    #
    # Minimal results of the calculation are saved to the associated node after
    # the calculation.
    class PseudoConsumerAdapter < Adapter
      def participant
        @participant ||= ::Merit::User.create(
          key: @converter.key,
          load_curve: consumption_curve
        )
      end

      def inject!
        target_api.dataset_lazy_set(:electricity_input_curve) do
          @participant.load_curve.to_a
        end
      end

      def input_of_electricity
        consumption_curve.sum * 3600
      end

      private

      def consumption_curve
        @graph.plugin(:merit).curves.profile(@config.group, @converter)
      end
    end
  end
end
