#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to send a trace to Grafana Cloud
# Run with: bundle exec ruby test_grafana_connection.rb

require 'bundler/setup'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

puts "🔧 Configuring OpenTelemetry..."

# Load environment variables
require 'dotenv/load'

endpoint = ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
auth = ENV['GRAFANA_CLOUD_OTLP_AUTH']

if endpoint.nil? || endpoint.empty?
  puts "❌ ERROR: OTEL_EXPORTER_OTLP_ENDPOINT not set in .env"
  exit 1
end

if auth.nil? || auth.empty?
  puts "❌ ERROR: GRAFANA_CLOUD_OTLP_AUTH not set in .env"
  exit 1
end

puts "✅ Endpoint: #{endpoint}"
puts "✅ Auth: #{auth[0..20]}... (truncated)"

# Configure OpenTelemetry
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'etengine-connection-test'

  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'service.name' => 'etengine-connection-test',
    'service.version' => 'test',
    'deployment.environment' => 'test'
  )

  # Create OTLP exporter
  # Note: The endpoint should NOT include /v1/traces - the exporter adds it
  # But we need to ensure we're using the HTTP/protobuf endpoint
  traces_endpoint = endpoint.end_with?('/v1/traces') ? endpoint : "#{endpoint}/v1/traces"

  puts "📍 Full traces endpoint: #{traces_endpoint}"

  exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(
    endpoint: traces_endpoint,
    headers: {
      'Authorization' => "Basic #{auth}"
    },
    ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE # Disable SSL verification in development
  )

  # Add span processor
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)
  )
end

puts "\n🚀 Sending test trace to Grafana Cloud..."

# Get tracer
tracer = OpenTelemetry.tracer_provider.tracer('test-tracer', '1.0')

# Create a test trace
tracer.in_span('test-connection', attributes: {
  'test.type' => 'connection_test',
  'test.timestamp' => Time.now.to_s,
  'test.message' => 'Testing Grafana Cloud connection from ETM'
}) do |span|
  puts "📊 Created span with trace_id: #{span.context.hex_trace_id}"

  # Add some nested spans to make it interesting
  tracer.in_span('database-query-simulation') do
    sleep 0.1 # Simulate work
    puts "  ├─ Simulated database query"
  end

  tracer.in_span('api-call-simulation') do
    sleep 0.05 # Simulate work
    puts "  ├─ Simulated API call"
  end

  tracer.in_span('cache-lookup-simulation') do
    sleep 0.02 # Simulate work
    puts "  └─ Simulated cache lookup"
  end
end

puts "\n⏳ Flushing spans to Grafana..."

# Force flush to send immediately
OpenTelemetry.tracer_provider.shutdown

puts "✅ Test trace sent successfully!"
puts "\n📍 Next steps:"
puts "  1. Wait 10-30 seconds for trace to appear in Grafana"
puts "  2. Go to Grafana Cloud → Explore → Tempo"
puts "  3. Query: { service.name=\"etengine-connection-test\" }"
puts "  4. You should see a trace with 4 spans (parent + 3 children)"
puts "\n🔍 If you don't see traces:"
puts "  - Check credentials are correct"
puts "  - Wait a bit longer (can take up to 1 minute)"
puts "  - Check for errors above"
puts "  - Try the 'Test connection' button in Grafana again"
