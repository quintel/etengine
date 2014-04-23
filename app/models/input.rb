class Input
  include InMemoryRecord
  include CommandAttributes
  include ActiveModel::Validations

  extend ActiveModel::Naming

  validates :update_period, :presence => true,
                            :inclusion => %w[present future both before]

  ATTRIBUTES = [
    *Atlas::Input.attribute_set.map(&:name) - [:default_unit, :factor],
    :key
  ]

  attr_accessor *ATTRIBUTES
  attr_accessor :file_path

  def initialize(attrs={})
    attrs && attrs.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym
    end
  end

  def key=(new_key)
    new_key && (@key = new_key.to_s)
  end

  def self.get(key)
    super(key.to_s)
  end

  def self.load_records
    Hash[ Etsource::Loader.instance.inputs.map do |input|
      [input.key.to_s, input]
    end ]
  end

  def self.with_share_group
    all.select{|input| input.share_group.present?}
  end

  def self.in_share_group(q)
    all.select{|input| input.share_group == q}
  end

  def self.by_name(q)
    q.present? ? all.select{|input| input.key.include?(q)} : all
  end

  def self.with_queries_containing(q)
    all.select do |input|
      [:label_query, :query, :max_value_gql,
       :min_value_gql, :start_value_gql]. any? do |attr|
        input.send(attr).to_s.include? q
      end
    end
  end

  def self.before_inputs
    @before_inputs ||= all.select(&:before_update?)
  end

  def self.inputs_grouped
    @inputs_grouped ||= Input.with_share_group.group_by(&:share_group)
  end

  # Public: The GQL::Command which represents the string held in the +query+
  # attribute.
  def command
    @command ||= command_for(:query)
  end

  def before_update?
    update_period == 'before'
  end

  def updates_present?
    update_period == 'present' || update_period == 'both'
  end

  def updates_future?
    update_period == 'future' || update_period == 'both'
  end

  # make as_json work
  def id
    self.key
  end

  def as_json(options={})
    super(
      :methods => [:id, :max_value, :min_value, :start_value]
    )
  end

  def client_values(gql)
    {
      key => {
        :max_value   => max_value_for(gql),
        :min_value   => min_value_for(gql),
        :start_value => start_value_for(gql),
        :full_label  => full_label_for(gql),
        :disabled    => disabled_in_current_area?(gql)
      }
    }
  end

  # This creates a giant hash with all value-related attributes of the inputs. Some inputs
  # require dynamic values, though. Check #dynamic_start_values
  #
  # @param [Gql::Gql the gql the query should run against]
  #
  def self.static_values(gql)
    Input.all.inject({}) do |hsh, input|
      begin
        hsh.merge input.client_values(gql)
      rescue => ex
        Airbrake.notify(
          :error_message => "Input#static_values for input #{input.key} failed: #{ex}",
          :backtrace => caller,
          :parameters => {:input => input, :api_scenario => gql.scenario }) unless
           APP_CONFIG[:standalone]

        hsh
      end
    end
  end

  # See #static_values
  #
  def self.dynamic_start_values(gql)
    Input.all.select(&:dynamic_start_value?).inject({}) do |hsh, input|
      begin
        hsh.merge input.key => {
          :start_value => input.start_value_for(gql)
        }
      rescue => ex
        Airbrake.notify(
          :error_message => "Input#dynamic_start_values for input #{input.key} failed for api_session_id #{gql.scenario.id}",
          :backtrace => caller,
        :parameters => {:input => input, :api_scenario => gql.scenario }) unless APP_CONFIG[:standalone]
        hsh
      end
    end
  end

  # Returns the label shown alongside the input name in ETM.
  #
  # @param [Scenario, Gql::Gql] gql_or_scenario
  #   When given a GQL instance, the start value will be determined by
  #   performing the input's "label_query" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [String, nil]
  #   Returns nil if the input has no label.
  #
  def full_label_for(gql_or_scenario)
    if value = label_value_for(gql_or_scenario)
      "#{ value } #{ label }".strip.html_safe
    end
  end

  # Returns the numeric value calculated by the label query.
  #
  # @param [Scenario, Gql::Gql] gql_or_scenario
  #   When given a GQL instance, the start value will be determined by
  #   performing the input's "label_query" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [String, nil]
  #   Returns nil if the input has no label.
  #
  def label_value_for(gql_or_scenario)
    return nil unless @label_query.present?

    if gql_or_scenario.is_a?(Scenario)
      Input.cache.read(gql_or_scenario, self)[:label]
    else
      value = wrap_gql_errors(:label, true) do
        gql_or_scenario.query_present(@label_query)
      end

      value && value.round(2) || nil
    end
  end

  # Returns the input start value for a given Scenario or GQL instance.
  #
  # @param [Scenario, Gql::Gql] gql_or_scenario
  #   When given a GQL instance, the start value will be determined by
  #   performing the input's "start_value_gql" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [Numeric]
  #
  def start_value_for(gql_or_scenario)
    if gql_or_scenario.is_a?(Scenario)
      Input.cache.read(gql_or_scenario, self)[:default]
    elsif @start_value_gql.present?
      start = wrap_gql_errors(:start, true) do
        gql_or_scenario.query(@start_value_gql)
      end

      start || min_value_for(gql_or_scenario)
    else
      @start_value
    end
  end

  # Returns the input minimum value for a given Scenario or GQL instance.
  #
  # @param [Scenario, Gql::Gql] gql_or_scenario
  #   When given a GQL instance, the minimum value will be determined by
  #   performing the input's "min_value_gql" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [Numeric]
  #
  def min_value_for(gql_or_scenario)
    if gql_or_scenario.is_a?(Scenario)
      Input.cache.read(gql_or_scenario, self)[:min]
    elsif @min_value_gql.present?
      wrap_gql_errors(:min) { gql_or_scenario.query(@min_value_gql) }
    else
      @min_value || 0.0
    end
  end

  # Returns the input maximum value for a given Scenario or GQL instance.
  #
  # @param [Scenario, Gql::Gql] gql_or_scenario
  #   When given a GQL instance, the maximum value will be determined by
  #   performing the input's "max_value_gql" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [Numeric]
  #
  def max_value_for(gql_or_scenario)
    if gql_or_scenario.is_a?(Scenario)
      Input.cache.read(gql_or_scenario, self)[:max]
    elsif @max_value_gql.present?
      wrap_gql_errors(:max) { gql_or_scenario.query(@max_value_gql) }
    else
      @max_value || 0.0
    end
  end

  def dynamic_start_value?
    @start_value_gql && @start_value_gql.match(/^future:/) != nil
  end

  # Area Dependent Min / Max / Disabled Settings -----------------------------

  # Returns if the Input is disabled in the area of the given scenario or
  # Gql instance.
  #
  # @param [Scenario, Gql::Gql] gql_or_scenario
  #   When given a GQL instance, the disabled status will be determined by
  #   checking the area data. When given a Scenario, the cached value will
  #   instead be returned.
  #
  # @return [true, false]
  #
  def disabled_in_current_area?(gql_or_scenario)
    if gql_or_scenario.is_a?(Scenario)
      return Input.cache.read(gql_or_scenario, self)[:disabled]
    end

    scenario = gql_or_scenario.scenario

    dependent_on.present? && ! scenario.area[dependent_on]
  end

  # @return [String]
  #   A human-readable version of the Input for debugging.
  #
  def inspect
    "#<Input #{ key.inspect }>"
  end

  # Runs the given block, wrapping any errors raised in an exception which
  # provides information about in which input and method the error was caused.
  #
  # Used primarily to provide more descriptive GQL errors for min/max values.
  #
  # @param [Symbol] attribute
  #   The attribute being calculated by GQL. One of :min, :max, :start or
  #   :label.
  #
  # @return [Object]
  #   Returns whatever the block returned.
  #
  # @example
  #   wrap_exceptions(:min) { gql.query(@min_value_gql) }
  #
  def wrap_gql_errors(attribute, allow_nil = false)
    begin
      value = yield

      if value.nil? && ! allow_nil
        raise "#{ attribute } GQL value for #{ @key } input returned nil"
      end

      value
    rescue Exception => e
      raise InputGQLError.new(e, self, attribute)
    end
  end

  private :wrap_gql_errors

  # Value Caching ------------------------------------------------------------

  def self.cache
    @_cache ||= Input::Cache.new
  end

  class Cache
    # Retrieves the hash containing all of the input attributes.
    #
    # If no values for the area and year are already cached, the entire input
    # collection values will be calculated and cached.
    #
    # @param [Scenario] scenario
    #   A scenario with an area code and end year.
    # @param [Input] input
    #   The input whose values are to be retrieved.
    #
    def read(scenario, input)
      cache_key = input_cache_key(scenario, input)

      Rails.cache.read(cache_key) ||
        ( warm_values_for(scenario) && Rails.cache.read(cache_key) )
    end

    #######
    private
    #######

    # Sets the hash containing all of the input attributes.
    #
    # @param [Scenario] scenario
    #   A scenario with an area code and end year.
    # @param [Input] input
    #   The input whose values are to be set.
    # @param [Hash{Symbol=>Numeric}] values
    #   Values for the input.
    #
    def set(scenario, input, values)
      Rails.cache.write(input_cache_key(scenario, input), values)
    end

    # Given a scenario, pre-calculates the values for each input using the
    # scenario area and end year, and stores them in memcache for fast
    # retrieval later.
    #
    # @param [Scenario] scenario
    #   A scenario with an area code and end year. All other attributes are
    #   ignored.
    #
    def warm_values_for(scenario)
      attributes = scenario.attributes.slice('area_code', 'end_year')
      gql        = Scenario.new(attributes).gql

      Input.all.each do |input|
        set(scenario, input, values_for(input, gql))
      end
    end

    # Returns the values which should be cached for an input.
    #
    # @param [Input] input
    #   The input whose values are to be cached.
    # @param [Gql::Gql] gql
    #   GQL instance for calculating values.
    #
    def values_for(input, gql)
      values = {
        min:      input.min_value_for(gql),
        max:      input.max_value_for(gql),
        default:  input.start_value_for(gql),
        label:    input.label_value_for(gql),
        disabled: input.disabled_in_current_area?(gql)
      }

      required_numerics = values.slice(:min, :max, :default).values

      if required_numerics.any? { |value| ! value.kind_of?(Numeric) }
        { disabled: true, error: 'Non-numeric GQL value' }
      else
        values
      end
    end

    # Given a scenario, returns the key used to store cached minimum, maximum,
    # and start values.
    #
    # @param [Scenario] scenario
    #   The scenario containing an area code and end year.
    # @param [Input] input
    #   The input whose key you want.
    #
    def input_cache_key(scenario, input)
      area = scenario.area_code || :unknown
      year = scenario.end_year  || :unknown
      key  = input.kind_of?(Input) ? input.key : input

      "#{ area }.#{ year }.inputs.#{ key }.values"
    end
  end # Cache

  # Errors -------------------------------------------------------------------

  # Used when calculating a min, max, start, etc, value fails to provide users
  # with some idea of where the error occurred.
  class InputGQLError < RuntimeError
    def initialize(original_exception, input, attribute)
      @original  = original_exception
      @key       = input.key
      @attribute = attribute

      set_backtrace(@original.backtrace)
    end

    def message
      "Failed to calculate #{ @attribute } value for #{ @key } input, " \
        "with error: #{ @original.message }"
    end
  end # InputGQLError

end # Input
