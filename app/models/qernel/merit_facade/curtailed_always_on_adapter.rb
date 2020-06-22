# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up a producer whose demand is determined by a fixed profile, but
    # where that profile may be curtailed based on a value set by the user.
    class CurtailedAlwaysOnAdapter < AlwaysOnAdapter
      def initialize(*args)
        super

        # The original carrier output is neede so that we can calculate a
        # curtailment curve.
        @original_output =
          @node.public_send(@context.carrier_named('output_of_%s'))
      end

      def inject!
        super

        inject_curve!(full_name: :curtailment_output_curve) do
          profile_builder.curtailment_curve(@original_output)
        end

        output = @node.node.output(@context.carrier)
        out_links = output.links

        return unless out_links.one? && out_links.first.link_type == :constant

        demand = target_api.demand * output.conversion

        out_links.first.dataset_set(:value, demand)
        out_links.first.dataset_set(:calculated, true)
      end

      private

      def install_demand!
        super

        output = @node.node.output(@context.carrier)
        target_api.demand = @participant.production(:mj) / output.conversion
      end

      def production_profile
        profile_builder.useable_profile
      end

      # Internal: Creates a class which will create the useable profile for the
      # participant, accounting for curtailment.
      def profile_builder
        @profile_builder ||=
          begin
            curtailment = @config.production_curtailment || 0.0

            if curtailment.positive? && @config.group.to_s.starts_with?('self:')
              raise 'Cannot use non-zero production_curtailment with a ' \
                    "\"self:...\" curve in #{@node.key}"
            end

            CurtailedProfile.new(
              @context.curves.curve(@config.group, @node),
              curtailment
            )
          end
      end
    end
  end
end
