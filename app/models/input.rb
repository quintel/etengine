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

class Input < ActiveRecord::Base
  has_paper_trail
  strip_attributes! :only => [:start_value_gql, :min_value_gql, :max_value_gql, :start_value, :min_value, :max_value]

  UPDATEABLE_PERIODS = %w[present future both].freeze

  has_many :expert_predictions

  scope :with_share_group, where('NOT(share_group IS NULL OR share_group = "")')

  scope :contains, lambda{|search| 
    where([
      "start_value_gql LIKE :q OR min_value_gql LIKE :q OR max_value_gql LIKE :q OR `keys` LIKE :q OR `attr_name` LIKE :q",
      {:q => "%#{search}%"}
    ])
  }
  
  # quite useful on bulk updates
  scope :embedded_gql_contains, lambda{|search| 
    where([
      "start_value_gql LIKE :q OR min_value_gql LIKE :q OR max_value_gql LIKE :q OR attr_name LIKE :q OR label_query LIKE :q",
      {:q => "%#{search}%"}
    ])
  }

  validates :updateable_period, :presence => true,
                                :inclusion => UPDATEABLE_PERIODS

  after_create :reset_all_cached

  def self.get_cached(key)
    all_cached[key.to_s]
  end

  def reset_all_cached
    self.class.reset_all_cached
  end

  def self.reset_all_cached
    @all_cached = nil
  end

  def self.all_cached
    unless @all_cached
      #@all_cached = nil
      #benchmark("** Loading Input.all_cached") do
        @all_cached = Input.all.inject({}) do |hsh, input| 
          hsh = hsh.merge input.id.to_s => input
          hsh.merge input.key => input if input.key.present?
          hsh
        end
      #end
    end
    @all_cached
  end

  def self.inputs_grouped
    @inputs_grouped ||= Input.
      with_share_group.select('id, share_group, `key`').
      group_by(&:share_group)
  end

  def v2?
    if Rails.env.test?
      query.present?
    else
      query.present? && !(attr_name == 'decrease_total')
    end
  end

  def updates_present?
    updateable_period != 'future'
  end

  def updates_future?
    updateable_period != 'present'
  end

  ##
  # update hash for this input with the given value.
  # {'converters' => {'converter_keys' => {'demand_growth' => 2.4}}}
  #
  # @param [Float] value the (user) value of that input
  # @return [Hash]
  #
  def update_statement(value)
    
    ##
    # When a fce slider is touched it should not generate an update_statement by itself. It needs the values of the other sliders as well
    # The Gql::UpdateInterface::FceCommand takes care of this.
    if update_type == 'fce'
      Gql::UpdateInterface::FceCommand.create(keys, attr_name, value / factor)
    else
      {
        update_type => {
          keys => {
            attr_name => value / factor
      }}}
    end
  end

  def as_json(options={})
    super(
      :only => [:id], :methods => [:max_value, :min_value, :start_value]
    )
  end

  def self.static_values
    Input.all.inject({}) do |hsh, input|
      begin 
        hsh.merge input.id.to_s => {
          :max_value    => input.max_value,
          :min_value    => input.min_value,
          :start_value  => input.start_value,
          :full_label   => input.full_label
        }
      rescue => ex
        Rails.logger.warn("Input#static_values for input #{input.id} failed for api_session_key #{Current.scenario.api_session_key}")
        Airbrake.notify(
          :error_message => "Input#static_values for input #{input.id} failed for api_session_key #{Current.scenario.api_session_key}",
          :backtrace => caller,
          :parameters => {:input => input, :api_scenario => Current.scenario })
        hsh
      end
    end
  end

  def self.dynamic_start_values
    Input.all.select(&:dynamic_start_value?).inject({}) do |hsh, input|
      begin
        hsh.merge input.id.to_s => {
          :start_value => input.start_value
        }
      rescue => ex
        Rails.logger.warn("Input#dynamic_start_values for input #{input.id} failed for api_session_key #{Current.scenario.api_session_key}")
        Airbrake.notify(
          :error_message => "Input#dynamic_start_values for input #{input.id} failed for api_session_key #{Current.scenario.api_session_key}",
          :backtrace => caller,
          :parameters => {:input => input, :api_scenario => Current.scenario })
        hsh
      end
    end
  end

  def user_value
    Current.scenario.user_value_for(self)
  end

  def full_label
    "#{Current.gql.query("present:#{label_query}").round(2)} #{label}".html_safe unless label_query.blank?
  end

  # TODO refactor (seb 2010-10-11)
  def start_value
    if gql_query = self[:start_value_gql] and !gql_query.blank? and result = Current.gql.query(gql_query)
      result * factor
    else
      self[:start_value]
    end
  end

  def dynamic_start_value?
    self[:start_value_gql] && self[:start_value_gql].match(/^future:/) != nil 
  end

  def min_value
    if gql_query = self[:min_value_gql] and !gql_query.blank?
      Current.gql.query(gql_query)
    else
      self[:min_value] || 0
    end
  end

  def max_value
    if gql_query = self[:max_value_gql] and !gql_query.blank?
      Current.gql.query(gql_query)
    else
      self[:max_value] || 0
    end
  end

  #############################################
  # Methods that interact with a users values
  #############################################

  ##
  # The current value of this slider for the current user. If the user hasn't touched
  # the slider, its start value is return.
  #
  # @return [Float] Users value
  #
  def user_value
    Current.scenario.store_user_value(self, value || start_value || 0).round(2)
  end

  ##
  # Resets the user values
  #
  # @todo Probably this should be moved into a Scenario class
  #
  def reset
    val = Current.scenario.user_values.delete(self.id)
    if updates = Current.scenario.update_statements[update_type]
      if keys = updates[keys]
        val = keys.delete(attr_name)
      end
    end
  end

  def update_current(value)
    Current.scenario.update_input(self, value)
  end
end

