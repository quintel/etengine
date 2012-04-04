# Encapsulates and parses api requests.
#
#    api_request = ApiRequest.new(params)
#    api_request.apply_inputs
#
#    api_request.response
#
class ApiRequest
  GQUERY_KEY_SEPARATOR = ";".freeze
  API_ATTRIBUTES = [:user_values, :country, :region, :start_year, :end_year, :use_fce, :preset_scenario_id]

  attr_accessor :settings, :input, :reset, :use_fce, :sanitize_groups

  # gquery_keys is populated by {#r=} and {#result=}
  attr_reader :gquery_keys

  def initialize(attributes = {})
    @gquery_keys = []
    @api_scenario_id = attributes.delete(:id)

    Input.reset_all_cached if self.test_scenario?

    # DEBT SECURITY: we probably should whitelist attributes.
    # this assigns params[:r], params[:result], and other attr_accessors
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end

    # if params[:settings] are passed, update the scenario.
    if attributes.has_key?(:settings) && !scenario.new_record?
       # only update if scenario already exists
      scenario.update_attributes(attributes[:settings])
    end
  end

  # Shortcut to {#response}. ApiScenariosController#show makes use of this method
  # extensively.
  #
  # @param [Hash] params request parameters
  #
  def self.response(params)
    api_request = new(params)
    api_request.apply_inputs
    api_request
  end

  # DEBT merge with ApiScenario.new_attributes
  def self.new_attributes(settings)
    opts = settings.present? ? settings : {}
    opts.each do |key,value|
      opts[key] = nil if value == 'null' or key == 'undefined'
    end
    ApiScenario.new_attributes(opts)
  end

  # Updates and stores the scenario with the new user values submitted in this request.
  # This needs to be run before we call gql.prepare otherwise they won't be applied.
  #
  def apply_inputs
    if @gql.andand.calculated? # access @gql directly to avoid initializing it in #gql
      raise "Gql has already been calculated. apply_inputs won't take effect"
    end
    if reset
      scenario.reset!
      scenario.save
      scenario.reload
      @scenario = nil;
      scenario
    end
    scenario.update_inputs_for_api(input, :sanitize_groups => sanitize_groups) if input
    scenario.use_fce = use_fce if use_fce
    scenario.save unless test_scenario?
  end

  # Initialize and return scenario. 
  def scenario
    @scenario ||= if test_scenario?
      ApiScenario.new(new_attributes).tap{|s| s.test_scenario = true }
    else
      ApiScenario.find(@api_scenario_id)
    end
  end

  # manually assign gql to this request. This is particularly
  # useful for testing.
  def gql=(gql)
    @gql = gql
  end

  # Access point for the GQL. 
  #
  def gql(options = {})
    unless @gql
      Current.scenario = scenario
      scenario.build_update_statements
      # This will load the graph and dataset from etsource
      # -> unoptimized and slow. It passed all test suites.
      options[:prepare] = true unless options.has_key?(:prepare)
      @gql = scenario.gql(options)
    end
    @gql
  end

  # This method runs the requested gqueries
  # Check ApiScenarioController#show
  # 
  def response
    {
      :result   => results,
      :settings => scenario_settings,
      :errors   => api_errors
    }.with_indifferent_access
  end

  protected

    def scenario_settings
      scenario.serializable_hash(:only => API_ATTRIBUTES)
    end

    def api_errors
      scenario.api_errors
    end

    # Let's run the queries!
    #
    def results
      gquery_keys.empty? ? nil : gql.query_multiple(gquery_keys)
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

    def new_attributes
      self.class.new_attributes(settings)
    end
end
