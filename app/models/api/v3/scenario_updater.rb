module Api
  module V3
    # Given a scenario, and parameters from an HTTP request, updates the
    # scenario with the data, or presents a useful error to sent back to the
    # client.
    class ScenarioUpdater
      include ActiveModel::Validations

      validate :validate_user_values
      validate :validate_groups_balance

      validates_with ActiveRecord::Validations::AssociatedValidator,
        attributes: [ :scenario ]

      # @return [Scenario]
      #   Returns the scenario being updated.
      #
      attr_reader :scenario

      # Creates a new ScenarioUpdater.
      #
      # @param [Scenario] scenario
      #   The scenario to be updated.
      # @param [#[]] params
      #   The HTTP parameters.
      #
      def initialize(scenario, params)
        @scenario      = scenario
        @data          = (params.to_h || {}).with_indifferent_access
        @scenario_data = (@data[:scenario] || {}).with_indifferent_access
      end

      # Applies the user changes to the scenario, saving the scenario back to
      # the database afterwards.
      #
      # @return [true, false]
      #   Returns if the update was a success.
      #
      def apply
        return true if @data.empty?

        @scenario.attributes = @scenario.attributes.except(
          "id", "present_updated_at", "created_at", "updated_at").merge(
          @scenario_data.except(:area_code, :end_year).merge(
            balanced_values: balanced_values,
            user_values:     user_values
        ))

        valid? ? @scenario.save(validate: false) : false
      end

      # Checks that the data given by the user is valid.
      #
      # @return [true, false]
      #
      def valid?(*args)
        super
      rescue RuntimeError => e
        # TODO Perhaps it is better to notify Airbrake, and add an error
        #      message with "something went wrong" and the Airbrake ID?
        errors.add(:base, e.message)
        false
      end

      #######
      private
      #######

      # @return [true, false]
      #   Returns if the scenario be reset to the default input values.
      #   Defaults to false.
      #
      def reset?
        @data.fetch(:reset, false)
      end

      # Validation -----------------------------------------------------------

      # Asserts that the values provided by the user are within the permitted
      # mininum and maximum.
      #
      def validate_user_values
        provided_values_without_resets.each do |key, value|
          input = Input.cache(@scenario).read(@scenario, Input.get(key))

          if input.blank?
            errors.add(:base, "Input #{key} does not exist")
          elsif value < (min = input[:min])
            errors.add(:base, "Input #{key} cannot be less than #{ min }")
          elsif value > (max = input[:max])
            errors.add(:base, "Input #{key} cannot be greater than #{ max }")
          end
        end
      end

      # Asserts that input values provided by the user correctly balance.
      #
      def validate_groups_balance
        each_group(provided_values) do |group, inputs|
          values = inputs.map do |input|
            input_cache = Input.cache(@scenario).read(@scenario, input)

            next if input_cache[:disabled]

            user_values[input.key] ||
              balanced_values[input.key] ||
              input_cache[:default]
          end.compact

          unless values.sum.between?(99.99, 100.01)
            info = inputs.map(&:key).zip(values).map do |key, value|
              "#{ key }=#{ value }"
            end.join(' ')

            errors.add(:base,
              "#{ group.to_s.inspect } group does not balance: group sums to " \
              "#{ values.sum } using #{ info }")
          end
        end
      end

      # User Values and Balancing --------------------------------------------

      # The values provided by the user in the current request.
      #
      # @return [Hash]
      #   The values. Inputs to be reset will be given the value :reset,
      #   otherwise the value will be cast to a float.
      #
      def provided_values
        @provided_values ||= begin
          values = @scenario_data[:user_values] || {}

          values.each_with_object({}) do |(key, value), collection|
            collection[key.to_s] = convert_provided_value(key, value)
          end
        end
      end

      # The values provided by the user, sans any which are to be reset.
      #
      # @return [Hash]
      #   The same as provided_values, without any whose value would be
      #   :reset.
      #
      def provided_values_without_resets
        provided_values.reject { |_, value| value == :reset }
      end

      # User-provided values, including those set in previous requests.
      #
      # @return [Hash{String=>Numeric}]
      #   Returns the user input values; inputs which are intended to be reset
      #   are removed from the hash.
      #
      def user_values
        @user_values ||= begin
          values = base_user_values

          provided_values.each do |key, value|
            value == :reset ? values.delete(key) : values[key] = value
          end

          values
        end
      end

      # Returns the values required to balance share groups.
      #
      # @return [Hash{String=>Numeric}]
      #   The hash will be empty if the entire scenario is being reset, or if
      #   the request did not ask for auto-balancing.
      #
      def balanced_values
        @balanced_values ||= begin
          if user_values.blank?
            {}
          else
            balanced = base_balanced_values

            # Remove balanced values for the entire groups which the user is
            # updating otherwise the group won't validate.
            each_group(provided_values) do |_, inputs|
              inputs.each { |input| balanced.delete(input.key) }
            end

            if @data[:autobalance] != 'false' && @data[:autobalance] != false
              each_group(provided_values) do |_, inputs|
                if balanced_group = balance_group(inputs)
                  balanced.merge!(balanced_group)
                end
              end
            end

            balanced
          end
        end
      end

      # Internal: Given a group of inputs belonging to a common share group,
      # balances the values provided by the user, with inputs which do not have
      # an explicit user value, in order that the group still sums to 100.
      #
      # Returns a hash of balanced values.
      def balance_group(inputs)
        if @data[:force_balance]
          balancer_values = provided_values

          # Force balancing deletes all values previously provided for
          # the group and permits their use in the balancer.
          inputs.each do |input|
            unless provided_values.key?(input.key)
              user_values.delete(input.key)
            end
          end

          Balancer.new(inputs).balance(@scenario, provided_values)
        else
          # "Normal" balancing prevents modifications to values for which the
          # user has provided an explicit value.
          Balancer.new(inputs).balance(@scenario, user_values)
        end
      rescue Balancer::BalancerError
        # It is acceptable for a balancer to fail; validation will
        # catch it and notify the user.
        #
        # TODO Notify Airbrake?
      end

      # Given a collection of user values, yields the name of each group to
      # which the inputs belong, and all of the inputs in the group. Each
      # group is yielded only once.
      #
      # @param [Hash{String=>Numeric}] values
      #   Input keys and values.
      #
      # @yieldparam [String] name
      #   The group name.
      # @yieldparam[Array<Input>] inputs
      #   The inputs which belong to the group.
      #
      def each_group(values)
        group_names = values.map do |key, _|
          (input = Input.get(key)) && input.share_group.presence || nil
        end.compact.uniq

        group_names.each do |name|
          yield name, Input.in_share_group(name)
        end

        nil
      end

      # Internal: Returns the parent scenario's value for `key` input.
      #
      # Returns a numeric, or nil if there is no parent, nor a user or balanced
      # value specified for the key.
      def value_from_parent(key)
        parent = @scenario.parent

        return nil unless parent

        parent.user_values[key] ||
          (parent.respond_to?(:balanced_values) && parent.balanced_values[key])
      end

      # Internal: Takes a value provided by a user and converts it to a number
      # or other value used by the updater.
      #
      # Returns a numeric or symbol.
      def convert_provided_value(key, value)
        if value == 'reset'
          value_from_parent(key) || :reset
        else
          value.to_f
        end
      end

      # Internal: A hash of starting user values.
      def base_user_values
        if reset?
          if @scenario.parent
            @scenario.parent.user_values.merge(provided_values)
          else
            provided_values.dup
          end
        else
          @scenario.user_values.dup
        end
      end

      # Internal: A hash of starting balanced values.
      def base_balanced_values
        if reset?
          @scenario.parent&.balanced_values || {}
        else
          (@scenario.balanced_values || {}).dup
        end
      end
    end # ScenarioUpdater
  end # V3
end # Api
