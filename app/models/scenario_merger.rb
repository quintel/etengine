class ScenarioMerger
  include ActiveModel::Validations

  Error = Class.new(RuntimeError)

  validate :scenarios_have_matching_areas
  validate :scenarios_have_matching_end_years
  validate :scenarios_are_not_scaled

  # Public: Builds a new scenario which results from merging those given.
  #
  # See ScenarioMerger#initialize.
  #
  # Returns a Scenario.
  def self.call(scenarios)
    new(scenarios).merged_scenario
  end

  # Public: Creates a Scenario merger.
  #
  # scenarios - An array containing elements which conform to the following
  #             structure: [scenario, weighting]. The weighting, which is
  #             optional, determines what relative weight should be applied to
  #             input values in this scenario.
  #
  # For example:
  #
  #   ScenarioMerger.new([
  #     [Scenario.first, 25]
  #     [Scenario.last,  75]
  #   ])
  #
  def initialize(scenarios)
    if scenarios.blank?
      fail Error, 'You must provide at least one scenario'
    end

    @scenarios   = scenarios.map(&:first)

    weights      = scenarios.map(&:last).compact
    total_weight = weights.sum.to_f
    avg_weight   = total_weight / weights.length

    if weights.length < @scenarios.length
      # Account for any scenarios which had an unspecified weight.
      total_weight += (avg_weight * (@scenarios.length - weights.length))
    end

    @weights = Hash[scenarios.map do |(scenario, weight)|
      [scenario, (weight || avg_weight).to_f / total_weight]
    end]
  end

  # Public: Returns the unsaved scenario resulting from the merging of the
  # scenarios given when the Merger was created.
  #
  # Returns a Scenario.
  def merged_scenario
    if @scenarios.one?
      build_scenario(scenario_id: @scenarios.first.id)
    else
      build_scenario(
        user_values:     values_from(:user_values),
        balanced_values: values_from(:balanced_values)
      )
    end
  end

  #######
  private
  #######

  # Internal: Builds a blank scenario to store the merged values.
  #
  # Returns a Scenario.
  def build_scenario(attrs = {})
    Scenario.new(attrs.merge(
      area_code: area_code,
      end_year:  end_year,
      source:   'ETEngine Merger'
    ))
  end

  # Internal: Merges input values from the scenarios for use in the merged
  # scenario.
  #
  # collection - :user_values or :balanced_values, depending on which collection
  #              of input values are being merged.
  #
  # Returns a hash.
  def values_from(collection)
    input_keys(collection).each_with_object({}) do |input, values|
      values[input] = input_value(collection, input)
    end
  end

  # Internal: Determines the value of a single input in the merged scenario.
  # Accounts for the weight of each scenario.
  #
  # collection - :user_values or :balanced_values, depending on which collection
  #              of input values are being merged.
  # input_key  - The key of the input whose value is to be calculated.
  #
  # Returns a Numeric.
  def input_value(collection, input_key)
    return enumerable_input_value(collection, input_key) if Input.get(input_key).enum?

    @scenarios.map do |scenario|
      @weights[scenario] * (
        scenario.public_send(collection)[input_key] ||
        Input.get(input_key).start_value_for(scenario) )
    end.sum
  end

  # Internal: Determines which value to use for an enum input.
  #
  # Selects the most frequently used value from the scenarios being merged.
  #
  # Returns a String.
  def enumerable_input_value(collection, input_key)
    values = @scenarios.map do |scenario|
      scenario.public_send(collection)[input_key] ||
        Input.get(input_key).start_value_for(scenario)
    end

    values.group_by { |key| key }.max_by { |(_, keys)| keys.length }.first
  end

  # Internal: Given the name of a collection (:user_values or :balanced_values)
  # returns a list of all input keys specified in all the scenarios to be
  # merged.
  #
  # collection - :user_values or :balanced_values, depending on which collection
  #              of input values are being merged.
  #
  # Returns an array of strings.
  def input_keys(collection)
    @scenarios
      .flat_map { |s| s.public_send(collection).keys }
      .uniq
      .select { |key| Input.get(key).present? }
  end

  # Internal: Returns the end year of the scenarios.
  def end_year
    @scenarios.first.end_year
  end

  # Internal: Returns the area code of the scenarios.
  def area_code
    @scenarios.first.area_code
  end

  # Internal: Asserts that the given scenarios all have the same end year.
  def scenarios_have_matching_end_years
    if @scenarios.map(&:end_year).any? { |year| year != end_year }
      errors.add(:base, 'One or more scenarios have differing end years')
    end
  end

  # Internal: Asserts that the given scenarios all have the same area code.
  def scenarios_have_matching_areas
    if @scenarios.map(&:area_code).any? { |area| area != area_code }
      errors.add(:base, 'One or more scenarios have differing area codes')
    end
  end

  # Internal: Asserts that the given scenarios are unscaled.
  def scenarios_are_not_scaled
    if @scenarios.any? { |scenario| scenario.scaler.present? }
      errors.add(:base, 'Cannot merge scenarios which have been scaled down')
    end
  end

  # Public: Given an array of scenarios to merge (with each member in the form
  # {:scenario_id, :weight}) creates a ScenarioMerger.
  #
  # Returns a ScenarioMerger.
  def self.from_params(params)
    params = params[:scenarios] || []

    scenario_ids = params.map { |p| p[:scenario_id].presence }.compact
    scenarios    = Scenario.where(id: scenario_ids).index_by { |s| s.id.to_s }

    ScenarioMerger.new(params.map do |details|
      if scenario = scenarios[details[:scenario_id]]
        [ scenario, details[:weight].presence.try(:to_f) ]
      end
    end.compact)
  end
end
