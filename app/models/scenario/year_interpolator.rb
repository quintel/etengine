# frozen_string_literal: true

# Receives a scenario and creates a new scenario with a new end year. Input
# values will be adjusted to linearly interpolate new values based on the year.
class Scenario::YearInterpolator

  def self.call(scenario, year, start_scenario = nil, current_user = nil)
    new(scenario, year, start_scenario, current_user).run
  end

  def initialize(scenario, year, start_scenario, current_user)
    @scenario = scenario
    @year = year
    @start_scenario = start_scenario
    @current_user = current_user
  end

  def run
    validate!
    clone = Scenario.new
    clone.copy_scenario_state(@scenario)

    clone.end_year = @year
    clone.source   = @scenario.source

    clone.scenario_users.destroy_all
    clone.user = @current_user if @current_user
    clone.reload unless clone.new_record?

    clone.private = @scenario.clone_should_be_private?(@current_user)

    if @year != @scenario.end_year
      clone.user_values = interpolate_input_collection(:user_values)
      clone.balanced_values = interpolate_input_collection(:balanced_values)
    end

    clone
  end

  private

  def validate!
    unless @year
      raise InterpolationError, 'Interpolated scenario must have an end year'
    end

    if @year > @scenario.end_year
      raise InterpolationError,
        'Interpolated scenario must have an end year equal or prior to the ' \
        "original scenario (#{@scenario.end_year})"
    end

    if @year < @scenario.start_year
      raise InterpolationError,
        'Interpolated scenario may not have an end year prior to the dataset ' \
        "analysis year (#{@scenario.start_year})"
    end

    if @scenario.scaler
      raise InterpolationError, 'Cannot interpolate scaled scenarios'
    end

    validate_start_scenario! if @start_scenario
  end

  def validate_start_scenario!
    if @start_scenario.id == @scenario.id
      raise InterpolationError,
        'Start scenario must not be the same as the original scenario'
    end

    if @start_scenario.end_year > @scenario.end_year
      raise InterpolationError,
        'Start scenario must have an end year equal or prior to the ' \
        "original scenario (#{@scenario.start_year})"
    end

    if @year < @start_scenario.end_year
      raise InterpolationError,
        'Interpolated scenario must have an end year equal or posterior to ' \
        "the start scenario (#{@start_scenario.end_year})"
    end

    if @start_scenario.start_year != @scenario.start_year
      raise InterpolationError,
        'Start scenario must have the same start year as the original ' \
        "scenario (#{@scenario.start_year})"
    end

    if @start_scenario.area_code != @scenario.area_code
      raise InterpolationError,
        'Start scenario must have the same area code as the original ' \
        "scenario (#{@scenario.area_code})"
    end
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

  class InterpolationError < RuntimeError; end
end
