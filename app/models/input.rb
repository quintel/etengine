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

  def self.fetch(key)
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
      cache_for(gql_or_scenario).read(gql_or_scenario, self)[:label]
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
      cache_for(gql_or_scenario).read(gql_or_scenario, self)[:default]
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
      cache_for(gql_or_scenario).read(gql_or_scenario, self)[:min]
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
      cache_for(gql_or_scenario).read(gql_or_scenario, self)[:max]
    elsif @max_value_gql.present?
      wrap_gql_errors(:max) { gql_or_scenario.query(@max_value_gql) }
    else
      @max_value || 0.0
    end
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

  # Public: Returns the appropriate cache for fetching a scenarios values,
  # depending on whether the scenario has been scaled.
  #
  # Returns an Input::Cache.
  def cache_for(scenario)
    Input.cache(scenario)
  end

  # Public: Retrieves the current input value cache. Supply an optional scenario
  # and the values in the cache will be scaled to fit the scaled area.
  def self.cache(scenario = nil)
    if scenario && scenario.scaler
      scenario.scaler.input_cache
    else
      @_cache ||= Cache.new
    end
  end

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
