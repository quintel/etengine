# == Schema Information
#
# Table name: input_elements
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
#  input_element_type        :string(255)
#  label                     :string(255)
#  comments                  :text
#  update_value              :string(255)
#  complexity                :integer(4)      default(1)
#  interface_group           :string(255)
#  update_max                :string(255)
#  locked_for_municipalities :boolean(1)
#  label_query               :string(255)
#

 # More defined in pkg/optimize/input_element.rb!!!
#
#
#
#
class InputElement < ActiveRecord::Base
  include AreaDependent
  has_paper_trail
  strip_attributes! :only => [:start_value_gql, :min_value_gql, :max_value_gql, :start_value, :min_value, :max_value]
  belongs_to :slide
  has_one :area_dependency, :as => :dependable
  has_many :expert_predictions

  scope :ordered_for_admin, order("slides.controller_name, slides.action_name, slides.name, input_elements.id").includes('slide')
  scope :max_complexity, lambda {|complexity| where("complexity <= #{complexity}") }
  
  scope :with_share_group, where('NOT(share_group IS NULL OR share_group = "")')

  scope :contains, lambda{|search| 
    where([
      "start_value_gql LIKE :q OR min_value_gql LIKE :q OR max_value_gql LIKE :q OR `keys` LIKE :q OR `attr_name` LIKE :q",
      {:q => "%#{search}%"}
    ])
  }

  def self.input_elements_grouped # TODO: delete?
    @input_elements_grouped ||= InputElement.
      with_share_group.select('id, share_group, `key`').
      group_by(&:share_group)
  end

  def step_value
    # cache(:step_value) do
      if Current.scenario.municipality? and self.locked_for_municipalities? and self.slide.andand.controller_name == "supply" 
        (self[:step_value] / 1000).to_f
      else
        self[:step_value].to_f
      end
      
    # end
  end

  def cache_conditions_key
    "%s_%s_%s_%s" % [self.class.name, self.id, Current.graph.id, Current.scenario.area.id]
  end

  # TODO refactor (seb 2010-10-11)
  def start_value
    return self[:start_value]
  end

  ##
  # update hash for this input_element with the given value.
  # {'converters' => {'converter_keys' => {'demand_growth' => 2.4}}}
  #
  # @param [Float] value the (user) value of that input_element
  # @return [Hash]
  #
  def update_statement(value)
    {
      update_type => {
        keys => {
          attr_name => value / factor
    }}}
  end

  def remainder?
    input_element_type == 'remainder'
  end

  def min_value
    self[:min_value] || 0
  end

  def max_value
    self[:max_value] || 0
  end

  def disabled
    has_locked_input_element_type?(input_element_type)
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
    unless input_element_type == "fixed" # if a slider is fixed, the user cant 
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


  ##### optimizer

  def update_current(value)
    # DON'T do that for now. because of DoubleGqlLoad Weirdness
    # value = value_within_range(value.to_f)
    # value = value.to_f
    # Current.user_values[id] = value
    # Current.update_user_updates({update_type => {
    #   keys => {attr_name => value / factor}
    # }})
    Current.scenario.update_input_element(self, value)
  end

  ##
  # @tested 2010-12-22 robbert
  #
  def has_locked_input_element_type?(input_type)
    %w[fixed remainder fixed_share].include?(input_type)
  end
end

