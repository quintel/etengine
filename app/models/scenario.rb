# == Schema Information
#
# Table name: scenarios
#
#  id                 :integer(4)      not null, primary key
#  author             :string(255)
#  title              :string(255)
#  description        :text
#  user_updates       :text
#  created_at         :datetime
#  updated_at         :datetime
#  user_values        :text
#  end_year           :integer(4)      default(2040)
#  country            :string(255)
#  in_start_menu      :boolean(1)
#  region             :string(255)
#  user_id            :integer(4)
#  complexity         :integer(4)      default(3)
#  scenario_type      :string(255)
#  preset_scenario_id :integer(4)
#  type               :string(255)
#  use_fce            :boolean(1)
#  present_updated_at :datetime
#  protected          :integer(1)
#

# Useage:
# Getting the default scenario:
#   Scenario.default
#
# A user updates a slider:
#   scenario.update_input(input, 4.5)
#
#
#
#
class Scenario < ActiveRecord::Base
  include Scenario::UserUpdates
  include Scenario::Persistable

  # has_paper_trail will break saving and laoding scenarios
  belongs_to :user

  # A scenario can have a preset. We use this
  # when it has to be reset to this scenario.
  #
  # @tested 2010-12-21 jape
  #
  has_one :preset_scenario, :foreign_key => 'preset_scenario_id', :class_name => 'Scenario'

  validates_presence_of :title, :on => :create, :message => I18n.t("scenario.provide_title")

  scope :in_start_menu, where(:in_start_menu => true)

  # it's a national preset scenario when there is no region defined and it's defined in the start menu
  scope :by_region, lambda {|region| where(:region => region) }
  scope :by_type, lambda {|type| where(:scenario_type => type.to_s)}
  scope :by_name, lambda{|q| where("title LIKE ?", "%#{q}%")}
  scope :exclude_api, where("`type` IS NULL OR `type` = 'Scenario'")
  scope :recent_first, order('created_at DESC')

  # let's define the conditions that make a scenario deletable. The table has
  # thousands of stale records. The user_values check is very ugly, I'm looking
  # forward to use Rails 3.2 and its ActiveRecord store - PZ 2012-02-02
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
  ])

  # before_validation :copy_scenario_state

  before_create do |scenario|
    if preset = scenario.preset_scenario
      scenario.copy_scenario_state(preset)
    end
  end

  after_initialize do |scenario|
    scenario.touch :present_updated_at
  end

  before_save :serialize_user_values

  def serialize_user_values
    if @user_values_hash
      self[:user_values] = @user_values_hash.to_yaml
    end
  end

  def fce_settings=(fce_settings)
    Rails.logger.warn("fce_settings is deprecated")
  end

  ##############################
  # Default Scenario
  ##############################

  def test_scenario=(flag)
    @test_scenario = flag
  end

  def test_scenario?
    @test_scenario == true
  end


  ##
  # @tested 2010-11-30 seb
  #
  def self.default(opts = {})
    new(default_attributes.merge(opts))
  end

  def code=(code)
    country = code
  end

  # Code is the new region_code/country.
  def code
    region.present? ? region : country
  end

  ##
  # @tested 2010-11-30 seb through self.default
  #
  def self.default_attributes
    {
      :complexity => 3,
      :country => 'nl',
      :user_values => {},
      :use_fce => false,
      :region => nil,
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


  ##############################
  # Scenario Attributes
  ##############################

  # @tested 2010-11-30 seb
  #
  def start_year
    2010
  end


  # @tested 2010-11-30 seb
  #
  def years
    end_year - start_year
  end

  # returns a hash with the user_values pairs that reference missing inputs
  #
  def invalid_user_values
    out = {}
    user_values.each_pair do |input_id, value|
      out[input_id] = value unless Input.find_by_id(input_id)
    end
    out
  end

  # removes invalid inputs from the user_values hash
  #
  def cleanup_user_values!
    cleaned_up = user_values
    invalid_user_values.keys.each do |input_id|
      cleaned_up.delete(input_id)
    end
    self.user_values = cleaned_up
    save!
  end

  # add all the attributes and methods that are modularized in calculator/
  # loads all the "open classes" in calculator
  Dir["app/models/scenario/*.rb"].sort.each {|file| require_dependency file }
end
