# frozen_string_literal: true

module Qernel
  module MeritFacade
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
        @participant ||= Merit::User.create(
          key: @converter.key,
          load_curve: consumption_curve
        )
      end

      def inject!
        inject_curve!(:input) { @participant.load_curve }
      end

      def input_of_carrier
        consumption_curve.sum * 3600
      end

      def installed?
        # Psuedo consumers are typically dynamic demands resulting from some
        # other time-resolved calculation. We can't be 100% sure that a demand
        # of zero on the node will still be zero after a dynamic demand is
        # computed.
        #
        # For example a hybrid heat pump may have no electricity demand by
        # default, but changes in temperature may result in it being assigned
        # on by the Fever heat calculation.
        true
      end

      private

      def consumption_curve
        @context.curves.curve(@config.group, @converter)
      end
    end
  end
end
