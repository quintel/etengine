class ScenarioScaling < ActiveRecord::Base
  # An array containing dataset attributes whose values will be scaled to fit
  # the reduced-size area.
  SCALEABLE_AREA_ATTRS = Atlas::Dataset.attribute_set
    .select { |attr| attr.options[:proportional] }.map(&:name).freeze

  belongs_to :scenario, inverse_of: :scaler

  validates :area_attribute,
    presence: true, inclusion: { in: %w( number_of_residences ) }

  validates :value, presence: true, numericality: true

  # Public: The number by which attributes will be scaled to fit the smaller
  # region.
  #
  # Returns a Float.
  def multiplier
    @multiplier ||= value.to_f / scenario.area[area_attribute]
  end

  # Public: Given a number, scales it to fit the reduced-area scenario.
  #
  # Returns a numeric.
  def scale(value)
    value.to_f * multiplier
  end

  # Public: An array of sectors; converters in these sectors will have their
  # demands set to zero by the graph.
  #
  # Returns an array.
  def disabled_sectors
    [ has_agriculture? ? nil : :agriculture,
      has_energy?      ? nil : :energy,
      has_industry?    ? nil : :industry ].compact
  end

  # Public: Given a dataset hash, scaled the values therein for the smaller
  # region. Changes the values IN-PLACE in the given hash, since datasets tend
  # to be large nested hashes, we want to avoid extra deep-clone calls.
  #
  # Returns the dataset hash.
  def scale_dataset!(dataset)
    scale_graph_dataset!(dataset.data[:graph])
    scale_area_dataset!(dataset.data[:area][:area_data])
    scale_time_curves!(dataset.data[:time_curves])

    dataset
  end

  # Public: Converts the scaling to a hash which can be serialized as JSON.
  #
  # Returns a Hash.
  def as_json(*)
    super(only: [:area_attribute, :value, :has_agriculture, :has_industry])
  end

  # Public: A human-readable version of the scenario scaling.
  #
  # Returns a string.
  def inspect
    "#<ScenarioScaling #{ area_attribute.inspect } (" \
      "#{ scenario.area[area_attribute].inspect } -> " \
      "#{ value.to_f.inspect })>"
  end

  # Public: Stores a cache of input values for the scenario.
  #
  # Returns an Input::ScaledInputs.
  def input_cache
    @input_cache ||= Input::ScaledInputs.new(Input.cache, scenario.gql)
  end

  #######
  private
  #######

  def scale_graph_dataset!(data)
    data.each do |_, element|
      # Nodes
      scale_hash_value(element, :preset_demand)
      scale_hash_value(element, :demand_expected_value)
      scale_hash_value(element, :number_of_units)

      # Edges
      scale_hash_value(element, :demand)

      if element[:max_demand].is_a?(Numeric)
        scale_hash_value(element, :max_demand)
      end

      if element[:type] == :constant
        # Constant-demand edges.
        scale_hash_value(element, :share)
      end
    end
  end

  def scale_area_dataset!(data)
    SCALEABLE_AREA_ATTRS.each do |key|
      scale_hash_value(data, key)
    end

    data[:disabled_sectors] ||= []
    data[:disabled_sectors] += self.disabled_sectors

    data
  end

  def scale_time_curves!(data)
    return unless data

    data.each_value do |curves|
      curves.each_value do |points|
        points.each_key { |year| scale_hash_value(points, year) }
      end
    end
  end

  def scale_hash_value(hash, key)
    hash[key] && hash[key] *= multiplier
  end
end # ScenarioScaling
