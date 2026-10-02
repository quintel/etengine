# frozen_string_literal: true

module Inspect
  module Scenarios
    # Renders the curves which have been attached to a scenario, showing which file or scenario
    # each one was replaced with, and a link to download it as CSV.
    class CurvesComponent < ApplicationComponent
      # The columns describing where a curve came from. The curve itself is a multi-megabyte blob
      # and a scenario may have dozens of them, so it is left out: nothing shown here reads the
      # values.
      CURVE_COLUMNS = %i[
        id
        key
        name
        source_dataset_key
        source_end_year
        source_saved_scenario_id
        source_scenario_id
        source_scenario_title
      ].freeze

      def initialize(scenario:)
        @scenario = scenario
      end

      # The curves attached to the scenario, ordered by key. Curves whose configuration has since
      # been removed from ETSource are left out, as the model ignores those too.
      def curves
        @curves ||= @scenario.user_curves
          .select(*CURVE_COLUMNS)
          .order(:key)
          .select { |curve| CurveHandler::Config.db_key?(curve.key) }
      end

      # The API endpoint which serves the curve as CSV, as the merit downloads elsewhere in the
      # admin UI do. The key is given without its "_curve" suffix, which is how the endpoint
      # identifies a curve. Built without the view's url options, which would otherwise append the
      # inspect interface's api_scenario_id to an API path that has no use for it.
      def download_path(curve)
        Rails.application.routes.url_helpers.api_v3_scenario_custom_curve_path(
          scenario_id: @scenario.id,
          id: curve.key.chomp('_curve'),
          format: :csv
        )
      end

      def source_scenario_path(curve)
        helpers.inspect_scenario_path(
          id: curve.source_scenario_id,
          api_scenario_id: curve.source_scenario_id
        )
      end

      # Describes the scenario a curve was imported from, for the title of the link to it.
      def source_scenario_description(curve)
        [
          curve.source_scenario_title,
          "#{curve.source_dataset_key} #{curve.source_end_year}",
          "saved scenario #{curve.source_saved_scenario_id}"
        ].join(' · ')
      end
    end
  end
end
