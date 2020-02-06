# frozen_string_literal: true

module Api
  module V3
    # Allows a block (typically a Rails action) to be wrapped with information
    # about the active scenario, so that any exceptions raised can provide
    # Sentry with relevant information.
    module ScenarioRavenContext
      module_function

      # Public: Wraps a block with Raven contexts about the scenario.
      #
      # scenario - The scenario whose information should be provided to Sentry
      #            if an exception happens.
      #
      # For example:
      #
      #   SentryRavenContext.with_context(scenario) do
      #     # any raised exceptions will provide sentry with scenario data.
      #   end
      #
      # Returns the result of the given block.
      def with_context(scenario)
        res = nil

        Raven.tags_context(etsource_tags) do
          Raven.extra_context(extra_context(scenario)) do
            res = yield
          end
        end

        res
      end

      def extra_context(scenario)
        {
          scenario_id: scenario.id,
          user_values: scenario.user_values,
          balanced_values: scenario.balanced_values
        }
      end

      private_class_method :extra_context

      def etsource_tags
        etsource_rev =
          NastyCache.instance.fetch('api.etsource_rev') do
            Etsource::Base.instance.get_latest_import_sha
          end

        { etsource_rev: etsource_rev }.compact
      end

      private_class_method :etsource_tags
    end
  end
end
