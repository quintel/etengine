# frozen_string_literal: true

# Usage:
# Getting the default scenario:
#   Scenario.default
class Scenario < ApplicationRecord
  extend Scenario::Migratable

  include Scenario::UserUpdates
  include Scenario::Persistable
  include Scenario::InputGroups
  include Scenario::Copies

  store :user_values
  store :balanced_values

  belongs_to :user
  has_one    :preset_scenario, :foreign_key => 'preset_scenario_id', :class_name => 'Scenario'
  has_one    :scaler, class_name: 'ScenarioScaling', dependent: :delete
  has_one    :flexibility_order, dependent: :destroy
  has_one    :heat_network_order, dependent: :destroy

  has_one_attached :imported_electricity_price_curve

  validates_presence_of :title, on: :create, message: 'Please provide a title'
  validates             :area_code, presence: true
  validates :area_code, inclusion: { in: ->(*) { Etsource::Dataset.region_codes } }
  validates :end_year,  numericality: true

  validate  :validate_no_yaml_error

  validates_associated :scaler, on: :create

  scope :in_start_menu, ->    { where(:in_start_menu => true) }
  scope :by_name,       ->(q) { where("title LIKE ?", "%#{q}%")}
  scope :by_id,         ->(q) { where(id: q)}

  # Expired ApiScenario will be deleted by rake task :clean_expired_api_scenarios
  scope :expired,       -> { where(['updated_at < ?', Date.today - 14]) }
  scope :recent,        -> { order("created_at DESC").limit(30) }
  scope :recent_first,  -> { order('created_at DESC') }

  # let's define the conditions that make a scenario deletable. The table has
  # thousands of stale records.
  scope(:deletable, lambda do
    where(%q[
        in_start_menu IS NULL
        AND protected IS NULL
        AND title = "API"
        AND author IS NULL
        AND user_id IS NULL
        AND (
          user_values IS NULL
          OR user_values = "--- !map:ActiveSupport::HashWithIndifferentAccess {}\n\n"
        )
        AND updated_at < ?
      ], Date.today - 5)
  end)

  attr_accessor :input_errors, :ordering, :display_group, :descale

  before_create do |scenario|
    if preset = scenario.preset_scenario
      scenario.copy_scenario_state(preset)
    end
  end

  def test_scenario=(flag)
    @test_scenario = flag
  end

  def test_scenario?
    @test_scenario == true
  end

  def self.default(opts = {})
    new(default_attributes.merge(opts))
  end

  def self.default_attributes
    {
      :area_code => 'nl',
      :user_values => {},
      :use_fce => false,
      :end_year => 2050,
      :title => 'API'
    }.with_indifferent_access
  end

  def self.new_attributes(settings = {})
    settings ||= {}
    attributes = Scenario.default_attributes.merge(:title => "API")
    out = attributes.merge(settings)
    # strip invalid attributes
    valid_attributes = [column_names, 'scenario_id'].flatten
    out.delete_if{|key,v| !valid_attributes.include?(key.to_s)}
    out
  end

  def area
    Area.get(area_code)
  end

  def scaled?
    scaler.present? || Area.derived?(area_code)
  end

  # Public: The year on which the analysis for the scenario's area is based.
  #
  # Returns an integer.
  def start_year
    @start_year ||=
      (Atlas::Dataset.exists?(area_code) &&
        Atlas::Dataset.find(area_code).analysis_year) ||
      2015
  end

  def years
    end_year - start_year
  end

  # Creates a scenario from a yml_file. Used by mech turk.
  def self.create_from_file(yml_file)
    settings = YAML::load(File.read(yml_file))['settings']
    Scenario.default(settings)
  end

  # Creates a scenario from a yml_file. Used by mech turk.
  def self.create_from_json(json_data)
    settings = JSON.parse(json_data)['settings']
    Scenario.default(settings)
  end

  # If you want to "prepare" the gql in a different way (hook into methods, etc)
  #
  # @example
  #     Scenario.default.gql # => default scenario gql
  #     scenario.gql         # => calculated scenario gql
  #
  # @example Customize (see Gql#initialize docs)
  #     Scenario.default.gql do |gql|
  #        gql.do_this_and_that ...
  #     end
  #
  # @example
  #     scenario.gql(prepare: false) # => gql without datasets, updates or calculated
  #
  #
  def gql(options = {}, &block)
    unless @gql

      if block_given?
        @gql = Gql::Gql.new(self, &block)
      else
        @gql = Gql::Gql.new(self)
        @gql.prepare if options.fetch(:prepare, true)
      end
      @gql.sandbox_mode = options.fetch(:sandbox_mode, :sandbox)
    end
    @gql
  end

  def save_as_scenario(params = {})
    params ||= {}
    attributes = self.attributes.merge(params)
    Scenario.create!(attributes)
  end

  # used when loading an existing scenario, preset or user-created
  def scenario_id=(preset_id)
    if preset = Preset.get(preset_id) || Scenario.find_by_id(preset_id)
      copy_scenario_state(preset)
      self.preset_scenario_id = preset_id
    end
  end

  # Public: Returns the parent preset or scenario.
  #
  # Use this over `parent_scenario` since `parent_scenario` will not check for
  # the existence of a preset.
  #
  # Returns a Scenario, or nil.
  def parent
    unless defined?(@parent)
      @parent = preset_scenario_id &&
        ( Preset.get(preset_scenario_id).try(:to_scenario) ||
          Scenario.find(preset_scenario_id) )
    end

    @parent
  end

  # a identifier for the scenario selector drop down in data.
  # => "#32341 - nl 2040 (2011-01-11)"
  def identifier
    "##{id} - #{area_code} #{end_year} (#{created_at.strftime("%m-%d %H:%M")})"
  end

  # shortcut to run GQL queries
  def query(q)
    gql(prepare: true).query(q)
  end

  # Public: Given an input, returns the value of that input as it will be used
  # within GQL/Qernel.
  #
  # If no user value is present, the default input value is retrieved instead.
  #
  # Raises an ArgumentError if the given +input+ does not have a +key+ method.
  #
  # Returns a float.
  def input_value(input)
    unless input.respond_to?(:key)
      raise ArgumentError, "#{ input.inspect } is not an input"
    end

    user_values[input.key] ||
      balanced_values[input.key] ||
      input.start_value_for(self)
  end

  def flexibility_order
    super || FlexibilityOrder.default(scenario_id: id)
  end

  def heat_network_order
    super || HeatNetworkOrder.default(scenario_id: id)
  end

  def user_sortables
    [flexibility_order, heat_network_order]
  end
end
