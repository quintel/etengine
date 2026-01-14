# frozen_string_literal: true

# Receives multiple scenario IDs and target end years, for each target end year it
# creates interpolated scenarios for each gap between consecutive @scenarios.
# If a target end year is prior to the end year of first of the given scenarios
# then it interpolates between the start and end year of the first given scenario.
class Scenario::BatchYearInterpolator
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  # Validates input for batch year interpolation
  class Contract < Dry::Validation::Contract
    params do
      required(:end_years).filled(:array).each(:integer)
    end
  end

  def self.call(scenarios:, end_years:, user: nil)
    new(scenarios:, end_years:, user:).call
  end

  def initialize(scenarios:, end_years:, user: nil)
    @scenarios = scenarios.sort_by(&:end_year)
    @end_years = end_years.sort
    @user = user
  end

  def call
    yield validate
    yield validate_scenarios
    yield validate_target_years

    interpolate_all
  end

  private

  def validate
    result = Contract.new.call(end_years: @end_years)

    result.success? ? Success(nil) : Failure(result.errors.to_h)
  end

  def validate_scenarios
    if @scenarios.any?(&:scaler)
      return Failure(scenario_ids: ['cannot interpolate scaled scenarios'])
    end

    # Validate all scenarios have same area_code (and therefore same end_year)
    unless @scenarios.uniq(&:area_code).length == 1
      return Failure(scenario_ids: ['all scenarios must have the same area code'])
    end

    Success(nil)
  end

  def validate_target_years
    @end_years.each do |year|
      if year <= @scenarios.first.start_year
        return Failure(end_years: ["#{year} must be posterior to the first scenario start year"])
      end
      if year >= @scenarios.last.end_year
        return Failure(end_years: ["#{year} must be prior to the latest scenario end year"])
      end
    end

    Success(nil)
  end

  def interpolate_all
    results = @end_years.filter_map do |target_year|
      # Find the scenario with end_year after the target (the one we interpolate from)
      later_scenario = @scenarios.find { |s| s.end_year > target_year }

      next unless later_scenario

      # Find the scenario with end_year before the target (used as start_scenario)
      # This may be nil if target_year is before the first scenario's end_year
      earlier_scenario = @scenarios.reverse.find { |s| s.end_year < target_year }

      result = Scenario::YearInterpolator.call(
        scenario: later_scenario,
        year: target_year,
        start_scenario: earlier_scenario,
        user: @user
      )

      if result.failure?
        msg = "failed to interpolate year #{target_year}: #{result.failure.values.flatten.join(', ')}"
        return Failure(interpolation: [msg])
      end

      result.value!
    end

    Success(results)
  end
end
