# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry/exporter/otlp'

# OpenTelemetry configuration for distributed tracing
# Sends trace data to Grafana Cloud Tempo for visualization and analysis
# Sentry continues to handle error tracking independently

# Only enable in development for now (can be extended to production later)
if Rails.env.development?
  OpenTelemetry::SDK.configure do |c|
    # Set service name for identification in Grafana
    c.service_name = 'etengine'

    # Add resource attributes for better trace context
    c.resource = OpenTelemetry::SDK::Resources::Resource.create(
      'service.name' => 'etengine',
      'service.version' => Settings.release&.to_s || 'unknown',
      'deployment.environment' => Rails.env.to_s
    )

    # Auto-instrument Rails, Sidekiq, HTTP clients, database, Redis, etc.
    # This provides automatic span creation for:
    # - Rails controllers, views, and Active Record queries
    # - Sidekiq background jobs
    # - HTTP requests via Net::HTTP, Faraday, RestClient
    # - Redis operations
    # - ActiveSupport::Notifications events
    c.use_all

    # Configure OTLP exporter to send traces to Grafana Cloud
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(
          endpoint: ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://localhost:4318/v1/traces'),
          headers: {
            'Authorization' => "Basic #{ENV.fetch('GRAFANA_CLOUD_OTLP_AUTH', '')}"
          },
          ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE # Disable SSL verification in development
        )
      )
    )
  end
end
