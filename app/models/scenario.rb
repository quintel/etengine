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
#  api_session_key    :string(255)
#  use_fce            :boolean(1)
#  present_updated_at :datetime
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
  include Scenario::FceSettings


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
  scope :exclude_api, where("`type` IS NULL OR `type` = 'Scenario'")
  scope :recent_first, order('created_at DESC')

  # before_validation :copy_scenario_state

  before_create do |scenario|
    if preset = scenario.preset_scenario
      scenario.copy_scenario_state(preset)
    end
  end

  before_save :serialize_user_values

  def serialize_user_values
    if @user_values_hash
      self[:user_values] = @user_values_hash.to_yaml
    end
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
  def self.default
    Scenario.new(default_attributes)
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

  
  ##############################
  # Scenario Attributes
  ##############################

  ##
  # @tested 2010-11-30 seb
  # 
  def start_year
    2010
  end


  ##
  # @tested 2010-11-30 seb
  # 
  def years
    end_year - start_year
  end

  # add all the attributes and methods that are modularized in calculator/
  # loads all the "open classes" in calculator
  Dir["app/models/scenario/*.rb"].sort.each {|file| require_dependency file }
end
