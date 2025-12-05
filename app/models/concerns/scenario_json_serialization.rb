# frozen_string_literal: true

# Shared JSON serialization methods for scenarios.
# Provides consistent serialization of sortables and curves across
# different serializers and packer classes.
module ScenarioJsonSerialization
  extend ActiveSupport::Concern

  # Serializes user sortables into a hash grouped by class.
  # HeatNetworkOrder instances are aggregated into an array,
  # while other sortables are stored as single objects.
  #
  # @return [Hash] sortables grouped by class name
  #
  # @example
  #   scenario.serialize_sortables
  #   # => {
  #   #   "HeatNetworkOrder" => [
  #   #     {"temperature" => "ht", "order" => [...]},
  #   #     {"temperature" => "mt", "order" => [...]}
  #   #   ],
  #   #   "ForecastStorageOrder" => {"order" => [...]}
  #   # }
  def serialize_sortables
    user_sortables.each_with_object({}) do |sortable, hash|
      next unless sortable.persisted?

      if sortable.is_a?(HeatNetworkOrder)
        hash[sortable.class] ||= []
        hash[sortable.class] << sortable.as_json.merge(temperature: sortable.temperature)
      else
        hash[sortable.class] = sortable.as_json
      end
    end
  end

  # Serializes user curves into a hash keyed by curve name.
  # Each curve is converted to an array of values.
  #
  # @return [Hash] curves keyed by curve name
  #
  # @example
  #   scenario.serialize_curves
  #   # => {
  #   #   "curve_one" => [0, 1, 2, 3],
  #   #   "curve_two" => [4, 5, 6, 7]
  #   # }
  def serialize_curves
    user_curves.each_with_object({}) do |curve, hash|
      hash[curve.key] = curve.curve.to_a
    end
  end
end
