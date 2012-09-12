# == Schema Information
#
# Table name: scenarios
#
#  id                 :integer(4)      not null, primary key
#  author             :string(255)
#  title              :string(255)
#  description        :text
#  created_at         :datetime
#  updated_at         :datetime
#  user_values        :text
#  end_year           :integer(4)      default(2040)
#  in_start_menu      :boolean(1)
#  user_id            :integer(4)
#  preset_scenario_id :integer(4)
#  use_fce            :boolean(1)
#  present_updated_at :datetime
#  protected          :integer(1)
#  area_code          :string(255)
#  source             :string(255)
#

# Useage:
# Getting the default scenario:
#   Scenario.default
#
# A user updates a slider:
#   scenario.update_input(input, 4.5)
#
class Scenario < ActiveRecord::Base
  include Scenario::UserUpdates
  include Scenario::Persistable
  include Scenario::InputGroups
  include Scenario::Copies
  include Api::V2::ScenarioHelpers

  store :user_values
  store :balanced_values

  belongs_to :user
  has_one               :preset_scenario, :foreign_key => 'preset_scenario_id', :class_name => 'Scenario'

  validates_presence_of :title, :on => :create, :message => "Please provide a title"
  validates             :area_code, :presence => true

  scope :in_start_menu, where(:in_start_menu => true)
  scope :by_name,       lambda{|q| where("title LIKE ?", "%#{q}%")}
  scope :by_id,         lambda{|q| where(id: q)}
  # Expired ApiScenario will be deleted by rake task :clean_expired_api_scenarios
  scope :expired,       lambda { where(['updated_at < ?', Date.today - 14]) }
  scope :recent,        order("created_at DESC").limit(30)
  scope :recent_first,  order('created_at DESC')

  # let's define the conditions that make a scenario deletable. The table has
  # thousands of stale records.
  scope :deletable, where(%q[
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

  attr_accessible :author, :title, :description, :user_values,
    :balanced_values, :end_year, :area_code, :country, :region,
    :in_start_menu, :user_id, :preset_scenario_id, :use_fce, :protected,
    :scenario_id, :source, :user_values_as_yaml

  attr_accessor :input_errors

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
      :end_year => 2040,
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

  def area_input_values
    hash = area[:input_values]
    if hash.present?
      YAML::load(hash).with_indifferent_access
    else
      {}
    end
  end

  def start_year
    START_YEAR
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
  #   scenario.gql(prepare: false)
  def gql(options = {})
    unless @gql
      @gql = Gql::Gql.new(self)
      @gql.prepare if options.fetch(:prepare, true)
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

  # a identifier for the scenario selector drop down in data.
  # => "#32341 - nl 2040 (2011-01-11)"
  def identifier
    "##{id} - #{area_code} #{end_year} (#{created_at.strftime("%m-%d %H:%M")})"
  end
end
