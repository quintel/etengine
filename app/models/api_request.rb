# Encapsulates and parses api requests.
#
class ApiRequest
  GQUERY_KEY_SEPARATOR = ";".freeze
  API_ATTRIBUTES = [:api_session_key, :user_values, :country, :region, :start_year, :end_year, :use_fce, :preset_scenario_id]

  
  attr_accessor :settings, :input, :reset, :use_fce

  # gquery_keys is populated by {#r=} and {#result=}
  attr_reader :gquery_keys

  def initialize(attributes = {})
    @gquery_keys = []
    @api_scenario_id = attributes.delete(:id)

    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end

    Current.scenario = scenario
  end

  # Shortcut to {#response}
  #
  # @param [Hash] params request parameters
  #
  def self.response(params)
    api_request = new(params)
    api_request.apply_inputs
    api_request.response
  end

  def gql
    @gql ||= Current.gql
  end

  def response
    results = gquery_keys.nil? ? nil : gql.query_multiple(gquery_keys)

    {
      :result   => results,
      :settings => scenario.serializable_hash(:only => API_ATTRIBUTES),
      :errors   => scenario.api_errors
    }.with_indifferent_access
  end

  def apply_inputs
    scenario.reset! if reset    
    scenario.update_inputs_for_api(input) if input
    scenario.use_fce = use_fce if use_fce
    scenario.save unless test_scenario?
  end

  def scenario
    @scenario ||= if test_scenario?
      ApiScenario.new(new_attributes)
    else
      ApiScenario.find_by_api_session_key(@api_scenario_id)
    end
  end

  # :r is a String of gquery_keys separated by {GQUERY_KEY_SEPARATOR}
  #
  def r=(keys)
    @gquery_keys += keys.split(GQUERY_KEY_SEPARATOR).reject(&:blank?)
  end

  # :result is an array of gquery_keys
  #
  def result=(keys)
    @gquery_keys += keys.map(&:to_s).reject(&:blank?)
  end

  def test_scenario?
    @api_scenario_id == 'test'
  end

  # DEBT merge with ApiScenario.new_attributes
  def self.new_attributes(settings)
    opts = settings.present? ? settings : {}
    opts.each do |key,value|
      opts[key] = nil if value == 'null' or key == 'undefined'
    end
    ApiScenario.new_attributes(opts)
  end

  def new_attributes
    self.class.new_attributes(settings)
  end
end