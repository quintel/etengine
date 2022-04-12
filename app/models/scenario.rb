# frozen_string_literal: true

# Usage:
# Getting the default scenario:
#   Scenario.default
class Scenario < ApplicationRecord
  extend Scenario::Migratable

  include Scenario::Attachments
  include Scenario::UserUpdates
  include Scenario::Persistable
  include Scenario::InputGroups
  include Scenario::Copies

  store :user_values
  store :balanced_values
  store :metadata, coder: JSON

  belongs_to :user, optional: true
  has_one    :preset_scenario, :foreign_key => 'preset_scenario_id', :class_name => 'Scenario'
  has_one    :scaler, class_name: 'ScenarioScaling', dependent: :delete
  has_one    :heat_network_order, dependent: :destroy
  has_many   :attachments, dependent: :destroy, class_name: 'ScenarioAttachment'

  has_many :source_attachments,
    dependent: :nullify,
    class_name: 'ScenarioAttachment',
    foreign_key: :source_scenario_id,
    inverse_of: :source_scenario

  validates :area_code, presence: true
  validates :end_year,  numericality: true

  validates :area_code, inclusion: {
    in: ->(*) { Etsource::Dataset.region_codes },
    message: 'is unknown or not supported'
  }

  validate  :validate_metadata_size

  validates_associated :scaler, on: :create

  scope :in_start_menu, ->    { where(:in_start_menu => true) }
  scope :by_id,         ->(q) { where(id: q)}

  # Expired ApiScenario will be deleted by rake task :clean_expired_api_scenarios
  scope :expired,       -> { where(['updated_at < ?', Date.today - 14]) }
  scope :recent,        -> { order("created_at DESC").limit(30) }
  scope :recent_first,  -> { order('created_at DESC') }

  scope :with_attachments, -> { includes(attachments: { file_attachment: :blob }) }

  # let's define the conditions that make a scenario deletable. The table has
  # thousands of stale records.
  scope(:deletable, lambda do
    where(%q[
        in_start_menu IS NULL
        AND api_read_only = ?
        AND keep_compatible = ?
        AND author IS NULL
        AND user_id IS NULL
        AND (
          user_values IS NULL
          OR user_values = "--- !map:ActiveSupport::HashWithIndifferentAccess {}\n\n"
        )
        AND updated_at < ?
      ], false, false, Time.zone.today - 5)
  end)

  attr_accessor :input_errors, :ordering, :display_group, :descale

  before_create do |scenario|
    if preset = scenario.preset_scenario
      scenario.copy_scenario_state(preset)
    end
  end

  # before_save do |scenario|
  #   scenario.keep_compatible = true if api_read_only? && api_read_only_changed?
  # end

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
      :end_year => 2050
    }.with_indifferent_access
  end

  def self.new_attributes(settings = {})
    settings ||= {}
    attributes = Scenario.default_attributes
    out = attributes.merge(settings)
    # strip invalid attributes
    valid_attributes = [column_names, 'scenario_id'].flatten
    out.delete_if{|key,v| !valid_attributes.include?(key.to_s)}
    out
  end

  # Public: Finds a scenario by ID, eager loading associations which are typically used during
  # calculation.
  #
  # Returns the Scenario, or raises ActiveRecord::RecordNotFound if the scenario does not exist.
  def self.find_for_calculation(id)
    # where() doesn't raise RecordNotFound when the given ID is out-of-range (unlike find()). Detect
    # an out-of-range ID...
    id_attr = type_for_attribute(:id)
    id = id_attr.cast(id)

    if id.to_i >= 1 << (id_attr.limit * 8 - 1)
      raise(
        ActiveRecord::RecordNotFound,
        "Couldn't find Scenario with an out of range value for 'id'"
      )
    end

    where(id: id).with_attachments.first!
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

  def title
    metadata['title'].presence
  end

  # String form of the scenario mutability. Used in the admin scenario form.
  def mutability
    if api_read_only?
      'api-read-only'
    elsif keep_compatible?
      'keep-compatible'
    else
      'public'
    end
  end

  def outdated?
    !keep_compatible? && created_at < Scenario.default_migratable_date
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

  def heat_network_order
    super || HeatNetworkOrder.default(scenario_id: id)
  end

  def user_sortables
    [heat_network_order]
  end

  def started_from_esdl?
    attachment?('esdl_file')
  end

  private

  # Validation method for when a user sets their metadata.
  def validate_metadata_size
    errors.add(:metadata, 'can not exceed 64Kb') if metadata.to_s.bytesize > 64.kilobytes
  end
end
