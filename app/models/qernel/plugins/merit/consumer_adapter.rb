module Qernel::Plugins
  module Merit
    # Converts a Qernel::Converter to a Merit user.
    class ConsumerAdapter < Adapter
      def participant
        @participant ||= ::Merit::User.create(
          key: @converter.key,
          load_profile: @dataset.load_profile(@config.group),
          total_consumption: input_of_electricity
        )
      end

      def inject!
        # do nothing
      end

      def input_of_electricity
        if @converter.converter.input(:electricity)
          @converter.input_of_electricity
        elsif @converter.converter.input(:loss)
          # HV loss node does not have an electricity input.
          @converter.input_of_loss
        else
          raise "No acceptable consumption input for #{@converter.key}"
        end
      end
    end
  end
end
