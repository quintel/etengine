# frozen_string_literal: true

# Receives a scenario and creates a new scenario with a new end year. Input
# values will be adjusted to linearly interpolate new values based on the year.
class Scenario::YearInterpolator
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  class Contract < Dry::Validation::Contract
    option :scenario
    option :start_scenario_id, optional: true
    option :start_scenario, optional: true
    option :ability, optional: true

    params do
      required(:year).filled(:integer)
    end

    rule do
      base.failure('cannot interpolate scaled scenarios') if scenario.scaler
    end

    rule(:year) do
      key.failure("must be prior to the original scenario end year (#{scenario.end_year})") if value >= scenario.end_year
      key.failure("must be posterior to the dataset analysis year (#{scenario.start_year})") if value <= scenario.start_year
      key.failure("must be posterior to the start scenario end year (#{start_scenario.end_year})") if start_scenario && value <= start_scenario.end_year
    end

    rule do
      next base.failure('start scenario not found') if start_scenario_id && !start_scenario
      next unless start_scenario
      next base.failure('start scenario not accessible') if ability && !ability.can?(:read, start_scenario)

      base.failure('start scenario must not be the same as the original scenario') if start_scenario.id == scenario.id
      base.failure("start scenario must have an end year prior to the original scenario (#{scenario.end_year})") if start_scenario.end_year >= scenario.end_year
      base.failure("start scenario must have the same start year as the original scenario (#{scenario.start_year})") if start_scenario.start_year != scenario.start_year
      base.failure("start scenario must have the same area code as the original scenario (#{scenario.area_code})") if start_scenario.area_code != scenario.area_code
    end
  end

  def self.call(scenario, year, start_scenario_id = nil, user = nil, ability = nil)
    new(scenario:, year:, start_scenario_id:, user:, ability:).call
  end

  def initialize(scenario:, year:, start_scenario_id: nil, user: nil, ability: nil)
    @scenario = scenario
    @year = year
    @start_scenario_id = start_scenario_id
    @user = user
    @ability = ability
  end

  def call
    @start_scenario = Scenario.find_by(id: @start_scenario_id)

    yield validate
    interpolate_scenario
  end

  private

  def validate
    result = Contract.new(
      scenario: @scenario,
      start_scenario_id: @start_scenario_id,
      start_scenario: @start_scenario,
      ability: @ability
    ).call(year: @year)

    result.success? ? Success(nil) : Failure(result.errors.to_h)
  end

  def interpolate_scenario
    clone = Scenario.new
    clone.copy_scenario_state(@scenario)

    clone.end_year = @year
    clone.source   = @scenario.source

    clone.scenario_users.destroy_all
    clone.user = @user if @user
    clone.reload unless clone.new_record?

    clone.private = @scenario.clone_should_be_private?(@user)
    clone.user_values = interpolate_input_collection(:user_values)
    clone.balanced_values = interpolate_input_collection(:balanced_values)

    Success(clone)
  end

  # Internal: Receives a collection of inputs and interpolates the values to
  # fit the end year of the new scenario.
  #
  # For example, if the start year is 2020 and the source scenario is 2050, and
  # an input starts and 0 and the source value is 100, and the new scenario is
  # based in 2030, the input value will be 50.
  #
  # Returns the interpolated inputs.
  def interpolate_input_collection(collection_attribute)
    start_collection = @start_scenario&.public_send(collection_attribute)
    collection = @scenario.public_send(collection_attribute)
    start_year = @start_scenario&.end_year || @scenario.start_year
    total_years = @scenario.end_year - start_year
    elapsed_years = @year - start_year

    collection.each_with_object(collection.class.new) do |(key, value), interp|
      if (input = Input.get(key))
        start = start_collection&.[](key) || input.start_value_for(@scenario)
        interp[key] = interpolate_input(input, start, value, total_years, elapsed_years)
      end
    end
  end

  # Internal: Calculates the interpolated value of an input based on its current
  # value in the original scenario.
  #
  # Returns a Numeric or String value for the new user values.
  def interpolate_input(input, start, value, total_years, elapsed_years)
    return value if input.enum? || input.unit == 'bool'

    change_per_year = (value - start) / total_years

    start + (change_per_year * elapsed_years)
  end
end
