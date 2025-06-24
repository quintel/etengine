# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up a producer whose demand is determined by a fixed profile.
    class AlwaysOnAdapter < ProducerAdapter
      def inject!
        super

        inject_costs!
      end

      private

      def producer_attributes
        attrs = super

        attrs[:load_profile]    = production_profile
        attrs[:full_load_hours] = source_api.full_load_hours

        if @config.group.to_s.starts_with?('self:')
          attrs[:load_curve] = attrs.delete(:load_profile)
          attrs.delete(:full_load_hours)
        end

        attrs
      end

      def producer_class
        return Merit::CurveProducer if @config.group.to_s.starts_with?('self:')

        case @config.subtype
        when :volatile then Merit::VolatileProducer
        when :must_run, :import_must_run then Merit::MustRunProducer
        else
          raise "Unknown producer class for node '#{@node.key}'"
        end
      end

      def production_profile
        @context.curves.curve(@config.group, @node)
      end

      def inject_costs!
        # return unless we talk about electricty
        target_api.dataset_lazy_set(:revenue_hourly_electricity) do
          participant.revenue
        end

        target_api.dataset_lazy_set(:revenue_hourly_electricity_per_mwh) do
          participant.revenue_per_mwh
        end
      end
    end
  end
end
