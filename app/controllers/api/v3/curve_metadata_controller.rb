# frozen_string_literal: true

module Api
  module V3
    # Provides metadata about available hourly curves and annual exports.
    #
    # This controller serves as a discovery endpoint for clients to dynamically
    # determine which curves and exports are available without hardcoding them.
    # The metadata is sourced from CurveMetadataRegistry, which is populated by
    # the CurvesController and ExportController classes during initialization.
    #
    # Design rationale:
    # - Metadata lives alongside the controller actions that serve each curve
    # - Clients can discover new curves without a code change on their side
    #
    # A curve's name is repeated across its route, action, serializer and
    # registration; a request spec guards that these stay in sync.
    class CurveMetadataController < BaseController
      # GET /api/v3/curves/metadata
      #
      # Returns metadata about all available hourly output curves.
      # Each curve includes:
      # - name: The curve identifier (matches route and controller method)
      # - type: The curve type (merit_curve, price_curve, capacity_curve, etc.)
      # - description: Human-readable explanation of the curve contents
      #
      # Example response:
      #   {
      #     "hourly_outputs": [
      #       {
      #         "name": "electricity_profiles",
      #         "type": "merit_curve",
      #         "description": "Load on each participant in the electricity merit order"
      #       },
      #       ...
      #     ]
      #   }
      def curves
        render json: { hourly_outputs: CurveMetadataRegistry.all_curves }
      end

      # GET /api/v3/exports/metadata
      #
      # Returns metadata about all available annual exports.
      # Each export includes:
      # - name: The export identifier (matches route and controller method)
      # - description: Human-readable explanation of the export contents
      #
      # Example response:
      #   {
      #     "annual_exports": [
      #       {
      #         "name": "energy_flow",
      #         "description": "Energy flows by carrier (future year)"
      #       },
      #       ...
      #     ]
      #   }
      def exports
        render json: { annual_exports: CurveMetadataRegistry.all_exports }
      end
    end
  end
end
