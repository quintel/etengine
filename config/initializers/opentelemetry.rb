# frozen_string_literal: true

# Native OpenTelemetry tracing.
#
# Purpose: emit a server span for each inbound request, extracting the W3C
# `traceparent` that etmodel's client span injects, so the etengine span nests
# under the caller's span in one distributed trace. That correlation is what
# lets us isolate the internal-network hop as `client_span - server_span` per
# trace, independent of etengine's (variable) calculation time.
#
# Byproduct we want: the Rack instrumentation marks the server span's status as
# error on 5xx responses, giving a durable server-side error signal the Beyla
# spans never provided.
#
# This replaces the Beyla sidecar for etengine (both would otherwise emit a
# server span and double-count in the span-metrics generator). It coexists with
# Sentry, which stays for error tracking.
#
# Inert unless OTEL_EXPORTER_OTLP_ENDPOINT is set (wired per environment in the
# ansible compose env alongside SENTRY_DSN); dev/test stay untouched.
if ENV['OTEL_EXPORTER_OTLP_ENDPOINT'].present?
  require 'opentelemetry/sdk'
  require 'opentelemetry-exporter-otlp'
  require 'opentelemetry/instrumentation/rack'
  require 'opentelemetry/instrumentation/action_pack'

  OpenTelemetry::SDK.configure do |c|
    # service.name, service.namespace and deployment.environment come from
    # OTEL_SERVICE_NAME / OTEL_RESOURCE_ATTRIBUTES (set in the container env).
    c.use('OpenTelemetry::Instrumentation::ActionPack')
  end

  # The Rack tracer middleware is what extracts the inbound traceparent and opens
  # the server span. ActionPack's railtie normally inserts it via a
  # `config.before_initialize` hook — but that phase has already run by the time
  # config/initializers load, so the hook never fires. Insert it explicitly here,
  # exactly as the railtie would.
  Rails.application.config.middleware.insert_before(
    0,
    *OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args
  )
end
