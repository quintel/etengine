module Qernel::Plugins
  module Merit
    # Converts a Qernel::Converter to a Merit user.
    class ConsumerAdapter < Adapter
      def participant
        @participant ||= ::Merit::User.create(
          key: @converter.key,
          load_profile: @dataset.load_profile(@config.group),
          total_consumption: @converter.input_of_electricity
        )
      end

      def inject!
        # do nothing
      end
    end
  end
end
