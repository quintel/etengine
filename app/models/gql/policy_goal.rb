module Gql


# PolicyGoal-specific helper methods to display values to the user
# This should move to helpers since it is view code
module PolicyGoalFormatter
  # Formats a computed future
  def output_present_value
    case unit
      when :eur_pct
        Metric.performance_html(start_value, start_value)
      when :co2_pct
        Metric.performance_html(Current.scenario.area.co2_emission_1990, start_value)
      when :pct
        Metric.percentage_html(start_value, :signed => false)
      when :eur
        Metric.format_number(start_value, :precision => 2, :suffix => '', :signed => false)
      else
        Metric.format_number(start_value, :suffix => unit.to_s, :signed => false)
    end
  end

#TODO: merge output_future_value and output_present_value: RD
  # Formats a computed future
  def output_future_value
    case unit
      when :eur_pct
        Metric.performance_html(start_value, future_value)
      when :co2_pct
        Metric.performance_html(Current.scenario.area.co2_emission_1990, future_value)
      when :pct
        Metric.percentage_html(future_value, :signed => false)
      when :eur
        Metric.format_number(future_value, :precision => 2, :suffix => '', :signed => false)
      else
        Metric.format_number(future_value, :suffix => unit.to_s, :signed => false)
    end
  end

  # Formats a target value display the user's value for co2, net_*_import, renewable_percentage, and the
  # absolute target value (optionally with units) otherwise.
  def output_user_target
    return nil? unless user_value
    case display_format
      when :percentage  #  display user_values
        Metric.percentage_html(user_value, :signed => false)
      when :number
        Metric.format_number(target_value, :precision => 2)
      when :number_with_unit
        Metric.format_number(target_value, :suffix => unit.to_s, :signed => false)
    end
  end

end

class PolicyGoal

  attr_accessor :id, :key, :name, :query, :user_value

  # TODO change to use @display_format instead of attr_reader
  attr_reader :display_format, :unit
  private :display_format, :unit

  include PolicyGoalFormatter

  # a PolicyGoal typically compares a future value with some user-defined target value to
  # determine if the goal has been reached. These values are computed by GQL queries.
  #
  # == Expressing goals
  # Often the reached_query will be just be the GQL equivalent of (future_value <= target_value), e.g.
  # LESS_OR_EQUAL(Q(energy_dependence),GOAL(energy_dependence;target))
  # but it can vary per goal. For example, for renewable_percentage, we might have
  # GREATER_OR_EQUAL(Q(renewable_percentage),GOAL(renewable_percentage;target))
  #
  # reached_query will hold the GQL expression for determining if the goal has been reached
  #
  # @param id [Integer] unique database id
  # @param key [Symbol] unique name
  # @param name [Symbol] human readable descriptive name
  # @param query [String] GQL to compute the future value
  # @param display_format [Symbol] describes how to display values to the user
  # @param unit [Symbol] units of measurement the goal is expressed in
  # @param start_value_query [String] GQL to compute the start value, which also serves as a default target when none is given
  # reached_query - GQL to determine if the goal has been met.
  #
  # TODO refactor the 8 parameters (seb 2010-10-11)
  def initialize(id, key, name, query, display_format = :number, unit = nil, start_value_query = nil, reached_query = nil)
    self.id = id
    self.key = key.to_sym
    self.name = name
    self.query = query

    @display_format = display_format.to_sym
    @unit = unit.to_sym
    @start_value_query = start_value_query
    @reached_query = reached_query # not used yet
  end


  # returns an absolute value for the goal, even when the user specifies a factor to increase by
  def target_value
    case key
      # For :co2_emission target is relative to 1990 levels
      when :co2_emission
        increase_factor(user_value) * Current.scenario.area.co2_emission_1990
      # For :total_energy_cost and :electricity_cost target is relative to start_value
      when :total_energy_cost, :electricity_cost
        increase_factor(user_value) * start_value
      else # target is a user-supplied value
        (user_value || start_value).to_f
    end
  end

  alias target target_value

  # QUESTION ejp- can start_value be memoized? Callback to detect if the user moves a slider? What if user changes country?
  def start_value
    @start_value_query ? start_value_query_results.present_value : 0.0
  end

  alias current start_value

  def future_value
    query_results.future_value
  end

  def score
    return 0 if user_value.nil?
    score = (output_future_value.to_f - output_present_value.to_f)
    score /= (output_user_target.to_f - output_present_value.to_f) unless (output_future_value.to_f - output_present_value.to_f) == 0 
    if score > 1
      score = (1 -(score - 1))  
    end
    if score < 0
      score = 0
    end
    (score.round(2) * 100).to_i
  end
  
  def reached?
    return false if user_value.nil?
    Current.gql.query(@reached_query).future_value
    # old comparison logic
    # key == :renewable_percentage ? future_value >= target_value  : future_value <= target_value
  end

  def inspect
    "<Gql::PolicyGoal #{name} (#{key}) start=#{start_value} future=#{future_value} user=#{user_value ? user_value : 'nil'} target=#{target_value}>"
  end

  def to_s
    inspect
  end

private

  # ejp- can query_results be memoized? (it was before)
  def query_results
    @query_results = Current.gql.query(query)
  end

  def start_value_query_results
    Current.gql.query(@start_value_query)
  end

  def increase_factor(value)
    (1+(value || 0.0))
  end


end



end
