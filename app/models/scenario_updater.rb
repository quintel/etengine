# frozen_string_literal: true

# Usage:
#   result = ScenarioUpdater.new(scenario, params, current_user, skip_validation: false).call
#   if result.success?
#     scenario = result.value!
#   else
#     errors = result.failure
#   end
class ScenarioUpdater
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call, :validate, :process, :apply, :post_save)

  attr_reader :scenario, :params, :current_user, :skip_validation

  def initialize(scenario, params, current_user, skip_validation: false)
    @scenario = scenario
    @params = params
    @current_user = current_user
    @skip_validation = skip_validation
  end

  # Returns Success(scenario) or Failure(errors).
  def call
    return Success(scenario) if params.empty?

    scenario_data = extract_scenario_data

    validated     = yield validate(scenario_data)
    processed     = yield process(scenario_data, validated)
    mutated       = yield apply(scenario_data, processed)
    finalized     = yield post_save(scenario_data, mutated)

    Success(finalized)
  rescue RuntimeError => e
    Failure([e.message])
  end

  private

  # Validation
  def validate(scenario_data)
    _validated_params = yield validate_params
    provided_values   = yield parse_provided_values(scenario_data)
    _valid_inputs     = yield validate_input_values(provided_values)
    Success(provided_values)
  end

  # Processing
  def process(scenario_data, provided_values)
    active_couplings = scenario_data[:active_couplings]
    uncouple         = params[:uncouple]
    reset            = params[:reset]
    autobalance      = params[:autobalance] != 'false' && params[:autobalance] != false
    force_balance    = params[:force_balance]

    coupling_state  = yield process_couplings(provided_values, active_couplings, uncouple)
    user_values     = yield calculate_user_values(provided_values, coupling_state, reset)
    balanced_values = yield calculate_balanced_values(
      user_values, provided_values, coupling_state, reset, autobalance, force_balance
    )
    _balanced       = yield validate_balance(user_values, balanced_values, provided_values)

    Success([coupling_state, user_values, balanced_values])
  end

  # Persistance
  def apply(scenario_data, (coupling_state, user_values, balanced_values))
    _coupled_scenario = yield apply_couplings(coupling_state)
    attributes        = yield prepare_attributes(user_values, balanced_values, scenario_data)
    persisted         = yield persist_scenario(attributes)
    Success(persisted)
  end

  # Post-save
  def post_save(scenario_data, persisted)
    set_preset_roles = truthy?(scenario_data[:set_preset_roles])
    _post_saved = yield post_save_operations(set_preset_roles)
    Success(persisted)
  end

  def truthy?(value)
    [true, 'true', '1'].include?(value)
  end

  def extract_scenario_data
    params[:scenario] || {}
  end

  def validate_params
    @validate_params ||= -> { service(:ValidateParams).call(scenario, params, current_user) }
    @validate_params.call
  end

  def parse_provided_values(scenario_data)
    service(:ParseProvidedValues).call(scenario, scenario_data)
  end

  def validate_input_values(provided_values)
    service(:ValidateInputValues).call(scenario, provided_values, skip_validation)
  end

  def process_couplings(provided_values, active_couplings, uncouple)
    service(:ProcessCouplings).call(scenario, provided_values, active_couplings, uncouple)
  end

  def calculate_user_values(provided_values, coupling_state, reset)
    service(:CalculateUserValues).call(
      scenario,
      provided_values,
      coupling_state[:uncoupled_inputs],
      reset
    )
  end

  def calculate_balanced_values(user_values, provided_values, coupling_state, reset, autobalance, force_balance)
    service(:CalculateBalancedValues).call(
      scenario,
      user_values,
      provided_values,
      coupling_state[:uncoupled_inputs],
      reset,
      autobalance,
      force_balance
    )
  end

  def validate_balance(user_values, balanced_values, provided_values)
    service(:ValidateBalance).call(scenario, user_values, balanced_values, provided_values, skip_validation)
  end

  def apply_couplings(coupling_state)
    service(:ApplyCouplings).call(scenario, coupling_state)
  end

  def prepare_attributes(user_values, balanced_values, scenario_data)
    service(:PrepareAttributes).call(scenario, user_values, balanced_values, scenario_data)
  end

  def persist_scenario(attributes)
    service(:PersistScenario).call(scenario, attributes, skip_validation)
  end

  def post_save_operations(set_preset_roles)
    service(:PostSaveOperations).call(scenario, set_preset_roles, current_user)
  end

  # Helper to instantiate services
  def service(name)
    Services.const_get(name).new
  end
end
