module Gql
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
  class PolicyGoal
    attr_accessor :id, :key, :name, :query, :user_value

    # TODO change to use @display_format instead of attr_reader
    attr_reader :display_format, :unit
    private :display_format, :unit

    def initialize(opts = {})
      opts.reverse_merge!({ :display_format => :number })

      self.id    = opts[:id]
      self.key   = opts[:key].try(:to_sym)
      self.name  = opts[:name]
      self.query = opts[:query]

      @display_format    = opts[:display_format].try(:to_sym)
      @unit              = opts[:unit].try(:to_sym)
      @start_value_query = opts[:start_value_query]
      @reached_query     = opts[:reached_query] # not used yet
    end

    # returns an absolute value for the goal, even when the user specifies a factor to increase by
    def target_value
      case key
      when :co2_emission
        # For :co2_emission target is relative to 1990 levels
        increase_factor(user_value) * Current.scenario.area.co2_emission_1990
      when :total_energy_cost, :electricity_cost
        # For :total_energy_cost and :electricity_cost target is relative to start_value
        increase_factor(user_value) * start_value
      else
        # target is a user-supplied value
        (user_value || start_value).to_f
      end
    end
    alias_method :target, :target_value

    # QUESTION ejp- can start_value be memoized? Callback to detect if the user moves a slider? What if user changes country?
    def start_value
      @start_value_query ? start_value_query_results.present_value : 0.0
    end
    alias_method :current, :start_value

    def future_value
      Current.gql.query(query).future_value
    end

    def reached?
      return false if user_value.nil?
      Current.gql.query(@reached_query).future_value
    end

    def inspect
      "<Gql::PolicyGoal #{name} (#{key}) start=#{start_value} future=#{future_value} user=#{user_value ? user_value : 'nil'} target=#{target_value}>"
    end

    def to_s
      inspect
    end

    private

      def start_value_query_results
        Current.gql.query(@start_value_query)
      end

      def increase_factor(value)
        1 + (value || 0.0)
      end
  end
end
