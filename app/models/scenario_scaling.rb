class ScenarioScaling < ActiveRecord::Base
  # An array containing dataset attributes whose values will be scaled to fit
  # the reduced-size area.
  SCALEABLE_AREA_ATTRS = Atlas::Dataset.attribute_set
    .select { |attr| attr.options[:proportional] }.map(&:name).freeze

  # Area attributes which are always set to a specified value, regardless of the
  # original area setting.
  CUSTOM_AREA_ATTRS = { use_network_calculations: false }.freeze

  belongs_to :scenario, inverse_of: :scaler

  validates :area_attribute, presence: true, inclusion: {
    in: %w(number_of_residences number_of_inhabitants)
  }

  validates :value, presence: true, numericality: true
  validates :scenario_id, uniqueness: true

  # Public: Given al Atlas::Preset::Scaling, creates a ScenarioScaling with the
  # same attributes.
  #
  # Returns a ScenarioScaling.
  def self.from_atlas_scaling(scaling)
    new(scaling.attributes)
  end

  def self.from_scenario(scenario)
    scenario.scaler ||
      (scenario.area[:derived] && from_atlas_scaling(scenario.area[:scaling]))
  end

  # Public: Determines if the given input should have it's values scaled.
  #
  # Returns true or false.
  def self.scale_input?(input)
    ! Etsource::Config.unscaleable_units.include?(input.unit)
  end

  # Public: The number by which attributes will be scaled to fit the smaller
  # region.
  #
  # Returns a Float.
  def multiplier
    @multiplier ||= value.to_f / base_value
  end

  # Public: Given a number, scales it to fit the reduced-area scenario.
  #
  # Returns a numeric.
  def scale(value)
    value.to_f * multiplier
  end

  # Public: Given a scaled number, returns the value as it would be in a
  # full-size scenario.
  #
  # Returns a numeric.
  def descale(value)
    value.to_f / multiplier
  end

  # Public: An array of sectors; nodes in these sectors will have their
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

  # Public: Determines an appropriate "step" value for the input, accounting for how the value will
  # be scaled; if the parent dataset allows values 0-50GW and steps of 0.1GW, it makes no sense to
  # keep that step value when a scaled dataset allows values between 0-20MW.
  #
  # Returns a hash.
  def input_step(step_value)
    return unless step_value

    @input_divisor ||= 10**Math.log10(1 / multiplier).ceil
    step_value / @input_divisor
  end

  # Public: Converts the scaling to a hash which can be serialized as JSON.
  #
  # Returns a Hash.
  def as_json(*)
    super(except: [:id, :scenario_id])
  end

  # Public: A human-readable version of the scenario scaling.
  #
  # Returns a string.
  def inspect
    "#<ScenarioScaling #{ area_attribute.inspect } (" \
      "#{ scenario.area[area_attribute].inspect } -> " \
      "#{ value.to_f.inspect })>"
  end

  # Public: Returns the value of the scaling attribute in the original unscaled
  # scenario.
  def base_value
    super || scenario.area[area_attribute]
  end

  def input_cache
    @input_cache ||= Input::ScaledInputs.new(Input.cache, scenario.gql)
  end

  def set_base_with(base_scenario)
    graph = base_scenario.gql(prepare: false) do |gql|
      gql.init_datasets
      gql.update_present
      gql.update_future
    end.future

    self.base_value = graph.area(area_attribute)
  end

  private

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

    CUSTOM_AREA_ATTRS.each do |key, value|
      data[key] = value
    end

    data[:disabled_sectors] ||= []
    data[:disabled_sectors] += disabled_sectors

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

  def input_value(scenario, key, multiplier = 1.0)
    scenario.user_values[key] && scenario.user_values[key] * multiplier
  end
end # ScenarioScaling
