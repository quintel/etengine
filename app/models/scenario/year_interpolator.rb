# frozen_string_literal: true

# Receives a scenario and creates a new scenario with a new end year. Input
# values will be adjusted to linearly interpolate new values based on the year.
class Scenario::YearInterpolator
  class InterpolationError < RuntimeError; end

  def self.call(scenario, year)
    new(scenario, year).run
  end

  def initialize(scenario, year)
    @scenario = scenario
    @year = year
  end

  def run
    validate!

    clone = Scenario.new
    clone.copy_scenario_state(@scenario)

    clone.end_year = @year
    clone.title    = @scenario.title
    clone.source   = @scenario.source

    clone.user_values =
      interpolate_input_collection(@scenario.user_values)

    clone.balanced_values =
      interpolate_input_collection(@scenario.balanced_values)

    clone
  end

  private

  def validate!
    unless @year
      raise InterpolationError, 'Interpolated scenario must have an end year'
    end

    if @year >= @scenario.end_year
      raise InterpolationError,
        'Interpolated scenario must have an end year prior to the ' \
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
  end

  # Internal: Receives a collection of inputs and interpolates the values to
  # fit the end year of the new scenario.
  #
  # For example, if the start year is 2020 and the source scenario is 2050, and
  # an input starts and 0 and the source value is 100, and the new scenario is
  # based in 2030, the input value will be 50.
  #
  # Returns the interpolated inputs.
  def interpolate_input_collection(collection)
    year_delta = @scenario.end_year - @year
    total_years = @scenario.end_year - @scenario.start_year

    collection.each_with_object(collection.class.new) do |(key, value), interp|
      input = Input.get(key)

      next unless input

      start = input.start_value_for(@scenario)
      change_per_year = (value - start) / total_years

      interp[key] = start + change_per_year * (total_years - year_delta)
    end
  end
end
