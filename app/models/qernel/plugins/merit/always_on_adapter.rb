module Qernel::Plugins
  module Merit
    class AlwaysOnAdapter < ProducerAdapter
      private

      def producer_attributes
        attrs = super

        attrs[:load_profile]    = production_profile
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

      def production_profile
        name = @config.group.to_s

        if name.start_with?('dynamic:')
          dyn_name = name[8..-1].strip.to_sym

          if dyn_name == :solar_pv
            # Temporary special-case for solar PV which should interpolate
            # between min and max curves, rather than amplifying the min curve.
            @graph.plugin(:merit).curves.profile(dyn_name)
          else
            Merit::Util.amplify_curve(
              @dataset.load_profile("#{name[8..-1].strip.to_sym}_baseline"),
              @converter.full_load_hours
            )
          end
        else
          @dataset.load_profile(@config.group)
        end
      end
    end # AlwaysOnAdapter
  end # Merit
end
