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

class Input < ActiveRecord::Base
  module MemoizedRecord
    extend ActiveSupport::Concern
    
    included do |variable|
    end

    module ClassMethods
      def load_records
        h = {}
        Etsource::Loader.instance.inputs.each do |input| 
          h[input.lookup_id] = input
        end
        h
      end

      def all
        records.values
      end

      def records
        @records ||= load_records
      end

      def get(key)
        records[key.to_i]
      end

      def add(obj)
        records[obj.lookup_id] = obj
        obj
      end
    end
  end

  attr_accessor :lookup_id

  extend MemoizedRecord::ClassMethods
  
  validates :updateable_period, :presence => true,
                                :inclusion => %w[present future both before]

  strip_attributes! :only => [:start_value_gql, :min_value_gql, :max_value_gql, :max_value, :min_value, :start_value]

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
    # Input.update_all("id = #{new_id}", "id = #{self.id}")
    self.lookup_id = new_id
  end

  def self.before_inputs
    @before_inputs ||= all.select(&:before_update?)
  end

  def self.inputs_grouped
    @inputs_grouped ||= Input.with_share_group.group_by(&:share_group)
  end
  
  def bad_query?(*args)
    # these four queries only work with v1.
    [368,412,361,371].include?(self.lookup_id)
  end

  # Checks whether the inputs use the new update statements or the old
  # key/attr_name based implementation
  def v2?
    query.present? && !bad_query?
  end

  # i had to resort to a class method for "caching" procs
  # as somewhere inputs are marshaled (where??)
  def self.memoized_gql3_proc_for(input)
    @gql3_proc ||= {}
    @gql3_proc[input.lookup_id] ||= (input.gql3_proc)
  end

  def gql3
    # use memoized_gql3_proc_for for faster updates (50% increase)
    #gql3_proc
    self.class.memoized_gql3_proc_for(self)
  end

  def gql3_proc
    query and Gquery.gql3_proc(query)
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

  # update hash for this input with the given value.
  # {'converters' => {'converter_keys' => {'demand_growth' => 2.4}}}
  #
  # @param [Float] value the (user) value of that input
  # @return [Hash]
  #
  def update_statement(value)
    # sometimes value ends up being nil. TODO: figure out why
    final_value = value ? (value / factor) : nil      
    ActiveSupport::Notifications.instrument("gql.inputs.error", "#{keys} -> #{attr_name} value is nil") if final_value.nil?
    {
      update_type => {
        keys => {
          attr_name => final_value
        }
      }
    }
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
        :disabled    => disabled_in_current_area?
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
        Rails.logger.warn("Input#static_values for input #{input.lookup_id} failed.")
        Airbrake.notify(
          :error_message => "Input#static_values for input #{input.lookup_id} failed.",
          :backtrace => caller,
          :parameters => {:input => input, :api_scenario => Current.scenario }) unless
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
        hsh.merge input.lookup_id.to_s => {
          :start_value => input.start_value_for(gql)
        }
      rescue => ex
        Rails.logger.warn("Input#dynamic_start_values for input #{input.lookup_id} failed for api_session_id #{Current.scenario.id}. #{ex}")
        Airbrake.notify(
          :error_message => "Input#dynamic_start_values for input #{input.lookup_id} failed for api_session_id #{Current.scenario.id}",
          :backtrace => caller,
        :parameters => {:input => input, :api_scenario => Current.scenario }) unless
          APP_CONFIG[:standalone]
        hsh
      end
    end
  end

  def user_value
    Current.scenario.user_value_for(self)
  end

  def full_label_for(gql)
    "#{gql.query("present:#{label_query}").round(2)} #{label}".html_safe unless label_query.blank?
  end

  def start_value_for(gql)
    if gql_query = self[:start_value_gql] and !gql_query.blank? and result = gql.query(gql_query)
      result * factor
    else
      self[:start_value]
    end
  end

  def min_value_for(gql)
    if min_value_for_current_area.present?
      min_value_for_current_area * factor
    elsif gql_query = self[:min_value_gql] and !gql_query.blank?
      gql.query(gql_query)
    else
      self[:min_value] || 0
    end
  end

  def max_value_for(gql)
    if max_value_for_current_area.present?
      max_value_for_current_area * factor
    elsif
      gql_query = self[:max_value_gql] and !gql_query.blank?
      gql.query(gql_query)
    else
      self[:max_value] || 0
    end
  end

  def dynamic_start_value?
    self[:start_value_gql] && self[:start_value_gql].match(/^future:/) != nil
  end

  #############################################
  # Area Dependent min / max / fixed settings
  #############################################
  
  
  def min_value_for_current_area
    get_area_input_values.andand["min"]
  end

  def max_value_for_current_area
    get_area_input_values.andand["max"]
  end

  def disabled_in_current_area?
    get_area_input_values.andand['disabled'] || false
  end

  # this loads the hash with area dependent settings for the current inputs object
  def get_area_input_values
    hash = Current.scenario.area.andand.input_values
    if hash.present?
      YAML::load(hash)[id]
    else
      false
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
    val = Current.scenario.user_values.delete(self.lookup_id)
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
