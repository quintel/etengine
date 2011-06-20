# == Schema Information
#
# Table name: inputs
#
#  id                        :integer(4)      not null, primary key
#  name                      :string(255)
#  key                       :string(255)
#  keys                      :text
#  attr_name                 :string(255)
#  slide_id                  :integer(4)
#  share_group               :string(255)
#  start_value_gql           :string(255)
#  min_value_gql             :string(255)
#  max_value_gql             :string(255)
#  min_value                 :float
#  max_value                 :float
#  start_value               :float
#  order_by                  :float
#  step_value                :decimal(4, 2)
#  created_at                :datetime
#  updated_at                :datetime
#  update_type               :string(255)
#  unit                      :string(255)
#  factor                    :float
#  input_type        :string(255)
#  label                     :string(255)
#  comments                  :text
#  update_value              :string(255)
#  complexity                :integer(4)      default(1)
#  interface_group           :string(255)
#  update_max                :string(255)
#  locked_for_municipalities :boolean(1)
#  label_query               :string(255)
#

 # More defined in pkg/optimize/input.rb!!!
#
#
#
#
class Input < ActiveRecord::Base
  has_paper_trail
  strip_attributes! :only => [:start_value_gql, :min_value_gql, :max_value_gql, :start_value, :min_value, :max_value]
  belongs_to :slide
  has_one :area_dependency, :as => :dependable
  has_many :expert_predictions

  scope :max_complexity, lambda {|complexity| where("complexity <= #{complexity}") }
  
  scope :with_share_group, where('NOT(share_group IS NULL OR share_group = "")')

  scope :contains, lambda{|search| 
    where([
      "start_value_gql LIKE :q OR min_value_gql LIKE :q OR max_value_gql LIKE :q OR `keys` LIKE :q OR `attr_name` LIKE :q",
      {:q => "%#{search}%"}
    ])
  }

  def self.inputs_grouped # TODO: delete?
    @inputs_grouped ||= Input.
      with_share_group.select('id, share_group, `key`').
      group_by(&:share_group)
  end

  def step_value
    if Current.scenario.municipality? and self.locked_for_municipalities? and self.slide.andand.controller_name == "supply" 
      (self[:step_value] / 1000).to_f
    else
      self[:step_value].to_f
    end
  end

  ##
  # update hash for this input with the given value.
  # {'converters' => {'converter_keys' => {'demand_growth' => 2.4}}}
  #
  # @param [Float] value the (user) value of that input
  # @return [Hash]
  #
  def update_statement(value)
    if update_type == 'lce'
      Gql::Update::LceCommand.create(keys, attr_name, value / factor)
    else
      {
        update_type => {
          keys => {
            attr_name => value / factor
      }}}
    end
  end

  def remainder?
    input_type == 'remainder'
  end

  def as_json(options={})
    super(
      :only => [:id], :methods => [:max_value, :min_value, :start_value]
    )
  end

  def self.static_values
    Input.all.inject({}) do |hsh, input|
      hsh.merge input.id.to_s => {
        :max_value => input.max_value,
        :min_value => input.min_value,
        :start_value => input.start_value
      }
    end
  end

  def user_value
    Current.scenario.user_value_for(self)
  end

  # TODO refactor (seb 2010-10-11)
  def start_value
    if gql_query = self[:start_value_gql] and !gql_query.blank?
      Current.gql.query(gql_query) * factor
    else
      self[:start_value]
    end
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
    unless input_type == "fixed" # if a slider is fixed, the user cant 
      value = Current.scenario.user_value_for(self) 
    end
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

