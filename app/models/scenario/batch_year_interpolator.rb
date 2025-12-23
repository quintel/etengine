# frozen_string_literal: true

# Receives multiple scenario IDs and target end years, for each target end year it
# creates interpolated scenarios for each gap between consecutive scenarios.
# If a target end year is prior to the end year of first of the given scenarios
# then it interpolates between the start and end year of the first given scenario.
class Scenario::BatchYearInterpolator
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  class Contract < Dry::Validation::Contract
    params do
      required(:scenario_ids).filled(:array).each(:integer)
      required(:end_years).filled(:array).each(:integer)
    end

    rule(:scenario_ids) do
      key.failure('must contain at least 2 scenarios') if value.length < 2
    end
  end

  def self.call(scenario_ids:, end_years:, user: nil, ability: nil)
    new(scenario_ids:, end_years:, user:, ability:).call
  end

  def initialize(scenario_ids:, end_years:, user: nil, ability: nil)
    @scenario_ids = scenario_ids
    @end_years = end_years.sort
    @user = user
    @ability = ability
  end

  def call
    yield validate
    yield fetch_and_validate_scenarios
    yield validate_target_years
    interpolate_all
  end

  private

  def validate
    result = Contract.new.call(
      scenario_ids: @scenario_ids,
      end_years: @end_years
    )

    result.success? ? Success(nil) : Failure(result.errors.to_h)
  end

  def fetch_and_validate_scenarios
    @scenarios = Scenario.where(id: @scenario_ids).to_a

    if @scenarios.length != @scenario_ids.length
      missing = @scenario_ids - @scenarios.map(&:id)
      return Failure(scenario_ids: ["scenarios not found: #{missing.join(', ')}"])
    end

    if @ability
      inaccessible = @scenarios.reject { |s| @ability.can?(:read, s) }
      if inaccessible.any?
        return Failure(scenario_ids: ["scenarios not accessible: #{inaccessible.map(&:id).join(', ')}"])
      end
    end

    # Sort scenarios by end_year
    @scenarios.sort_by!(&:end_year)

    # Validate all scenarios have same start_year and area_code
    first = @scenarios.first
    @scenarios.each do |scenario|
      if scenario.scaler
        return Failure(scenario_ids: ["cannot interpolate scaled scenarios (scenario #{scenario.id} is scaled)"])
      end
      if scenario.start_year != first.start_year
        return Failure(scenario_ids: ["all scenarios must have the same start year (found #{scenario.start_year} and #{first.start_year})"])
      end
      if scenario.area_code != first.area_code
        return Failure(scenario_ids: ["all scenarios must have the same area code (found #{scenario.area_code} and #{first.area_code})"])
      end
    end

    Success(nil)
  end

  def validate_target_years
    start_year = @scenarios.first.start_year
    max_year = @scenarios.last.end_year

    @end_years.each do |year|
      if year <= start_year
        return Failure(end_years: ["target year #{year} must be posterior to the first scenario start year (#{start_year})"])
      end
      if year >= max_year
        return Failure(end_years: ["target year #{year} must be prior to the latest scenario end year (#{max_year})"])
      end
    end

    Success(nil)
  end

  def interpolate_all
    results = []

    @end_years.each do |target_year|
      # Find the scenario with end_year after the target (the one we interpolate from)
      later_scenario = @scenarios.find { |s| s.end_year > target_year }

      next unless later_scenario

      # Find the scenario with end_year before the target (used as start_scenario)
      # This may be nil if target_year is before the first scenario's end_year
      earlier_scenario = @scenarios.reverse.find { |s| s.end_year < target_year }

      result = Scenario::YearInterpolator.call(
        later_scenario,
        target_year,
        earlier_scenario&.id,
        @user,
        @ability
      )

      case result
      in Dry::Monads::Success(scenario)
        results << scenario
      in Dry::Monads::Failure(errors)
        return Failure(interpolation: ["failed to interpolate year #{target_year}: #{errors.values.flatten.join(', ')}"])
      end
    end

    Success(results)
  end
end
