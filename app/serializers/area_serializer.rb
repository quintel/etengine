# frozen_string_literal: true

class AreaSerializer
  # These attributes will be kept as part of the JSON representation of the
  # area when the user does not request all attributes (detailed=false).
  SPARSE_ATTRIBUTES = Set.new(%w[
    analysis_year
    area
    base_dataset
    derived
    geo_id
    group
    number_of_inhabitants
    number_of_residences
    scaling
    useable
  ]).freeze

  # Attributes beginning with these substrings will also be included when
  # detailed=false.
  SPARSE_PREFIXES = %w[has_ use_].freeze

  # Creates a new Area API serializer.
  #
  # area - The Api::Area to be presented as JSON
  def initialize(area, detailed: false)
    @resource = area
    @detailed = detailed
  end

  # Creates a Hash of the Area data suitable for conversion to JSON by
  # Rails.
  #
  # Returns a Hash.
  def as_json(*)
    data = @resource.as_json

    # For compatibility with ETModel, which expects a "useable"
    # attribute which tells it if the region may be chosen.
    data['useable'] = data['enabled']['etmodel']
    data.delete('enabled')

    strip_unwanted(data)
  end

  private

  def strip_unwanted(attributes)
    return attributes if @detailed

    attributes.select do |key, _|
      SPARSE_PREFIXES.any? { |prefix| key.start_with?(prefix) } ||
        SPARSE_ATTRIBUTES.include?(key)
    end
  end
end
