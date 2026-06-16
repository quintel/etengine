# frozen_string_literal: true

# Registry for curve and export metadata.
#
# Controllers declare their curves/exports here with a small DSL, so the metadata
# lives next to the actions that serve it and powers the /curves/metadata and
# /exports/metadata discovery endpoints.
#
# A curve's name still appears in several places (route, controller action,
# serializer filename and the registration below) which are not auto-derived from
# one another, so a request spec asserts every registered curve has a matching
# download route to catch drift.
module CurveMetadataRegistry
  # Curve type symbols, stored as '<type>_curve' strings. Extend when adding a
  # new curve type.
  CURVE_TYPES = %i[merit price capacity load fever reconciliation query].freeze

  class << self
    # Registers a new hourly curve
    #
    # @param name [Symbol] The curve name (must match controller method and route)
    # @param type [Symbol] The curve type (:merit, :price, :capacity, :load, :fever,
    #   :reconciliation, :query)
    # @param description [String] Human-readable description of what the curve contains
    #
    # @example
    #   CurveMetadataRegistry.register_curve(
    #     :electricity_profiles,
    #     type: :merit,
    #     description: 'Load on each participant in the electricity merit order'
    #   )
    def register_curve(name, type:, description:)
      curves[name] = {
        name: name.to_s,
        type: normalize_type(type),
        description: description
      }
    end

    # Registers a new annual export
    #
    # @param name [Symbol] The export name (must match controller method and route)
    # @param description [String] Human-readable description of what the export contains
    #
    # @example
    #   CurveMetadataRegistry.register_export(
    #     :energy_flow,
    #     description: 'Energy flows by carrier (future year)'
    #   )
    def register_export(name, description:)
      exports[name] = {
        name: name.to_s,
        description: description
      }
    end

    # Returns all registered hourly curves as an array of hashes
    #
    # @return [Array<Hash>] Array of curve metadata with keys: name, type, description
    def all_curves
      curves.values
    end

    # Returns all registered annual exports as an array of hashes
    #
    # @return [Array<Hash>] Array of export metadata with keys: name, description
    def all_exports
      exports.values
    end

    # Clears all registrations (useful for testing)
    def clear!
      curves.clear
      exports.clear
    end

    private

    def curves
      @curves ||= {}
    end

    def exports
      @exports ||= {}
    end

    # Stores a curve type symbol as its '<type>_curve' API string, e.g.
    # :merit => 'merit_curve'.
    def normalize_type(type)
      unless CURVE_TYPES.include?(type)
        raise ArgumentError,
          "Unknown curve type: #{type}. Valid types: #{CURVE_TYPES.map(&:inspect).join(', ')}"
      end

      "#{type}_curve"
    end
  end
end
