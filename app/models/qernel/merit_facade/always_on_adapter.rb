# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up a producer whose demand is determined by a fixed profile.
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
        when :volatile then Merit::VolatileProducer
        when :must_run then Merit::MustRunProducer
        else
          raise "Unknown producer class for converter '#{@converter.key}'"
        end
      end

      def production_profile
        @context.curves.curve(@config.group, @converter)
      end
    end
  end
end
