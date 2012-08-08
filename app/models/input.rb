# == Schema Information
#
# Table name: inputs
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  key               :string(255)
#  keys              :text
#  attr_name         :string(255)
#  share_group       :string(255)
#  start_value_gql   :string(255)
#  min_value_gql     :string(255)
#  max_value_gql     :string(255)
#  min_value         :float
#  max_value         :float
#  start_value       :float
#  created_at        :datetime
#  updated_at        :datetime
#  update_type       :string(255)
#  unit              :string(255)
#  factor            :float
#  label             :string(255)
#  comments          :text
#  label_query       :string(255)
#  updateable_period :string(255)     default("future"), not null
#  query             :text
#  v1_legacy_unit    :string(255)
#
# v1_legacy_unit is appended to the value provided by the user, and defines whether it
# is growth_rate (%y) or total growth (%) or absolute value ("")
#

class Input
  include InMemoryRecord
  extend ActiveModel::Naming
  include ActiveModel::Validations

  validates :updateable_period, :presence => true,
                                :inclusion => %w[present future both before]

  ATTRIBUTES = [
    :id,
    :key,
    :comments,
    :factor,
    :label,
    :label_query,
    :max_value,
    :max_value_gql,
    :min_value,
    :min_value_gql,
    :query,
    :share_group,
    :start_value,
    :start_value_gql,
    :unit,
    :updateable_period,
    :default_unit,
    :dependent_on,
    :lookup_id
  ]

  attr_accessor *ATTRIBUTES

  def initialize(attrs={})
    attrs && attrs.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym
    end
  end

  def self.load_records
    h = {}
    Etsource::Loader.instance.inputs.each do |input|
      h[input.lookup_id]      = input
      h[input.lookup_id.to_s] = input
      h[input.key]            = input
    end
    h
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

  def force_id(new_id)
    self.lookup_id = new_id
  end

  def self.before_inputs
    @before_inputs ||= all.select(&:before_update?)
  end

  def self.inputs_grouped
    @inputs_grouped ||= Input.with_share_group.group_by(&:share_group)
  end

  # i had to resort to a class method for "caching" procs
  # as somewhere inputs are marshaled (where??)
  def self.memoized_rubel_proc_for(input)
    @rubel_proc ||= {}
    @rubel_proc[input.lookup_id] ||= (input.rubel_proc)
  end

  def rubel
    # use memoized_rubel_proc_for for faster updates (50% increase)
    # rubel_proc
    self.class.memoized_rubel_proc_for(self)
  end

  def rubel_proc
    query and Gquery.rubel_proc(query)
  end

  def before_update?
    updateable_period == 'before'
  end

  def updates_present?
    updateable_period == 'present' || updateable_period == 'both'
  end

  def updates_future?
    updateable_period == 'future' || updateable_period == 'both'
  end

  # make as_json work
  def id
    self.lookup_id
  end

  def as_json(options={})
    super(
      :methods => [:id, :max_value, :min_value, :start_value]
    )
  end

  def client_values(gql)
    {
      lookup_id => {
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
        Rails.logger.warn("Input#static_values for input #{input.lookup_id} failed: #{ex}")
        Airbrake.notify(
          :error_message => "Input#static_values for input #{input.lookup_id} failed: #{ex}",
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
        hsh.merge input.lookup_id => {
          :start_value => input.start_value_for(gql)
        }
      rescue => ex
        Rails.logger.warn("Input#dynamic_start_values for input #{input.lookup_id} failed for api_session_id #{gql.scenario.id}. #{ex}")
        Airbrake.notify(
          :error_message => "Input#dynamic_start_values for input #{input.lookup_id} failed for api_session_id #{gql.scenario.id}",
          :backtrace => caller,
        :parameters => {:input => input, :api_scenario => gql.scenario }) unless APP_CONFIG[:standalone]
        hsh
      end
    end
  end

  def full_label_for(gql)
    return Input.cache.read(gql, self)[:label] if gql.is_a?(Scenario)
    "#{gql.query("present:#{label_query}").round(2)} #{label}".strip.html_safe unless label_query.blank?
  end

  # Returns the input start value for a given Scenario or GQL instance.
  #
  # @param [Scenario, Gql::Gql] gql
  #   When given a GQL instance, the start value will be determined by
  #   performing the input's "start_value_gql" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [Numeric]
  #
  def start_value_for(gql)
    return Input.cache.read(gql, self)[:default] if gql.is_a?(Scenario)

    gql_query = @start_value_gql

    if !gql_query.blank? and result = gql.query(gql_query)
      result * factor
    else
      start_value
    end
  end

  # Returns the input minimum value for a given Scenario or GQL instance.
  #
  # @param [Scenario, Gql::Gql] gql
  #   When given a GQL instance, the minimum value will be determined by
  #   performing the input's "min_value_gql" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [Numeric]
  #
  def min_value_for(gql)
    return Input.cache.read(gql, self)[:min] if gql.is_a?(Scenario)

    min_value = min_value_for_current_area(gql)
    if min_value.present?
      min_value * factor
    elsif gql_query = @min_value_gql and !gql_query.blank?
      gql.query(gql_query)
    else
      @min_value || 0
    end
  end

  # Returns the input maximum value for a given Scenario or GQL instance.
  #
  # @param [Scenario, Gql::Gql] gql
  #   When given a GQL instance, the maximum value will be determined by
  #   performing the input's "max_value_gql" query. When given a Scenario,
  #   the cached value will instead be returned.
  #
  # @return [Numeric]
  #
  def max_value_for(gql)
    return Input.cache.read(gql, self)[:max] if gql.is_a?(Scenario)

    max_value = max_value_for_current_area(gql)
    if max_value.present?
      max_value * factor
    elsif gql_query = @max_value_gql and !gql_query.blank?
      gql.query(gql_query)
    else
      @max_value || 0
    end
  end

  def dynamic_start_value?
    @start_value_gql && @start_value_gql.match(/^future:/) != nil
  end

  #############################################
  # Area Dependent min / max / fixed settings
  #############################################


  def min_value_for_current_area(gql = nil)
    area_input_values(gql).andand["min"]
  end

  def max_value_for_current_area(gql = nil)
    area_input_values(gql).andand["max"]
  end

  def disabled_in_current_area?(gql = nil)
    return Input.cache.read(gql, self)[:disabled] if gql.is_a?(Scenario)

    if gql.scenario.area_input_values['disabled']
      return true
    elsif dependent_on.present?
      return true if !gql.scenario.area[dependent_on]
    end
    false
  end

  # this loads the hash with area dependent settings for the current inputs object
  def area_input_values(gql)
    gql.scenario.area_input_values[id]
  end

  # Minimal input information. This is used on active resource request to get a
  # list of the available inputs. The energymixer answer form uses this to fill
  # this input select box
  def basic_attributes
    {
      :id => id,
      :key => key
    }
  end

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
        set(scenario, input, {
          min:      input.min_value_for(gql),
          max:      input.max_value_for(gql),
          default:  input.start_value_for(gql),
          label:    input.full_label_for(gql),
          disabled: input.disabled_in_current_area?(gql)
        })
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

      "#{ area }.#{ year }.inputs.#{ input.lookup_id }.values"
    end
  end # Cache

end # Input
