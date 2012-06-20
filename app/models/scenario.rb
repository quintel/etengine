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
  store :user_values

  belongs_to :user

  # A scenario can have a preset. We use this
  # when it has to be reset to this scenario.
  has_one :preset_scenario, :foreign_key => 'preset_scenario_id', :class_name => 'Scenario'

  validates_presence_of :title, :on => :create, :message => I18n.t("scenario.provide_title")
  validates :area_code, :presence => true

  scope :in_start_menu, where(:in_start_menu => true)
  scope :by_name, lambda{|q| where("title LIKE ?", "%#{q}%")}
  # Expired ApiScenario will be deleted by rake task :clean_expired_api_scenarios
  scope :expired, lambda { where(['updated_at < ?', Date.today - 14]) }
  scope :recent, order("created_at DESC").limit(30)
  scope :recent_first, order('created_at DESC')

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

  attr_accessible :author, :title, :description, :user_values, :end_year,
    :area_code, :country, :region, :in_start_menu, :user_id, :preset_scenario_id,
    :use_fce, :protected, :scenario_id, :source

  before_create do |scenario|
    if preset = scenario.preset_scenario
      scenario.copy_scenario_state(preset)
    end
  end

  def fce_settings=(fce_settings)
    Rails.logger.warn("fce_settings is deprecated")
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
      :end_year => 2040
    }.with_indifferent_access
  end

  def force_id(new_id)
    if new_id
      self.class.update_all("id = #{new_id}", "id = #{self.id}")
      self.id = new_id
    else
      raise "force_id no id given. #{new_id.inspect}"
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

  def self.new_attributes(settings = {})
    settings ||= {}
    attributes = Scenario.default_attributes.merge(:title => "API")
    out = attributes.merge(settings)
    # strip invalid attributes
    valid_attributes = [column_names, 'scenario_id'].flatten
    out.delete_if{|key,v| !valid_attributes.include?(key.to_s)}
    out
  end

  def gql(options = {})
    # Passing a scenario as an argument to the gql will load the graph and dataset from ETsource.
    @gql ||= Gql::Gql.new(self)
    # At this point gql is not "prepared" see {Gql::Gql#prepare}.
    # We could force it here to always prepare, but that would slow things down
    # when nothing has changed in a scenario. Uncommenting this would decrease performance
    # but could get rid of bugs introduced by forgetting to prepare in some cases when we
    # access the graph through the gql (e.g. @gql.present_graph.converters.map(&:demand)).

    prepare_gql if options[:prepare] == true
    @gql
  end

  def prepare_gql
    gql.prepare
    gql
  end

  # The values for the sliders for this api_scenario
  #
  def input_values
    prepare_gql

    values = Rails.cache.fetch("inputs.user_values.#{area_code}") do
      Input.static_values(gql)
    end

    Input.dynamic_start_values(gql).each do |id, dynamic_values|
      values[id][:start_value] = dynamic_values[:start_value] if values[id]
    end

    self.user_values.each do |id, user_value|
      values[id][:user_value] = user_value if values[id]
    end

    values
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

  def api_errors
    if used_groups_add_up?
       []
    else
      groups = used_groups_not_adding_up
      remove_groups_and_elements_not_adding_up!
      groups.map do |group, elements|
        element_ids = elements.map{|e| "#{e.id} [#{e.key || 'no_key'}]" }.join(', ')
        "Group '#{group}' does not add up to 100. Elements (#{element_ids}) "
      end
    end
  end

  # API requests make use of this. Check Api::ApiScenariosController#new
  #
  def as_json(options={})
    super(
      :only => [:user_values, :area_code, :end_year, :start_year, :id, :use_fce]
    )
  end

  # this is used by the active resource serialization
  def to_xml(options = {})
    options.merge!(:except => [:user_values])
    super(options)
  end

  # add all the attributes and methods that are modularized in calculator/
  # loads all the "open classes" in calculator
  Dir["app/models/scenario/*.rb"].each {|file| require_dependency file }
end
