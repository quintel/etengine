# frozen_string_literal: true

# Ensure CurvesController and ExportController are loaded to populate the registry
# This initializer guarantees that metadata registrations happen at application startup

Rails.application.config.to_prepare do
  CurveMetadataRegistry.clear!
  require_dependency 'api/v3/curves_controller'
  require_dependency 'api/v3/export_controller'
end
