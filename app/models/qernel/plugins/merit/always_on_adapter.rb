module Qernel::Plugins
  module Merit
    class AlwaysOnAdapter < ProducerAdapter
      private

      def producer_attributes
        attrs = super

        attrs[:load_profile]    = @dataset.load_profile(@config.group)
        attrs[:full_load_hours] = @converter.full_load_hours

        attrs
      end

      def producer_class
        case @config.type
        when :volatile then ::Merit::VolatileProducer
        when :must_run then ::Merit::MustRunProducer
        else
          fail "Unknown producer class for converter '#{ @converter.key }'"
        end
      end
    end # AlwaysOnAdapter
  end # Merit
end
