module Qernel::Plugins
  module Merit
    class AlwaysOnAdapter < ProducerAdapter
      private

      def producer_attributes
        attrs = super

        attrs[:load_profile]    = production_profile
        attrs[:full_load_hours] = source_api.full_load_hours

        attrs
      end

      def producer_class
        case @config.subtype
        when :volatile then ::Merit::VolatileProducer
        when :must_run then ::Merit::MustRunProducer
        else
          raise "Unknown producer class for converter '#{@converter.key}'"
        end
      end

      def production_profile
        @graph.plugin(:merit).curves.profile(@config.group, @converter)
      end
    end # AlwaysOnAdapter
  end # Merit
end
