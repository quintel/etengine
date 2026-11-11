# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates that input share groups sum to 100%.
    class ValidateBalance
      include Dry::Monads[:result]

      # The representation tolerance: absorbs the float re-summation of values
      # that are exactly 100 as Rationals.
      REPRESENTATION_TOLERANCE = 1.0E-12

      SHARE_GROUP_TOTAL = 1.0E2

      def call(scenario, user_values:, balanced_values:, provided_values:, skip_validation: false)
        return Success(true) if skip_validation

        errors = []

        ShareGroups.each(provided_values) do |group, inputs|
          check_group_balance(group, inputs, scenario, user_values, balanced_values, errors)
        end

        errors.empty? ? Success(true) : Failure(errors)
      end

      private

      def check_group_balance(group, inputs, scenario, user_values, balanced_values, errors)
        balancer  = ::Balancer.new(inputs)
        values    = balancer.member_values(scenario, user_values, balanced_values)
        deviation = (values.values.sum - SHARE_GROUP_TOTAL).abs

        return if deviation <= REPRESENTATION_TOLERANCE

        errors << group_error(balancer, scenario, values, deviation)
      rescue ::Balancer::UnresolvableGroup => e
        errors << "#{group.to_s.inspect} group cannot be resolved: the value of " \
                  "#{e.input_key} cannot be determined (#{e.cache_error || 'input is disabled'})"
      end

      def group_error(balancer, scenario, values, deviation)
        breaches =
          if deviation <= ::Balancer::INTENT_TOLERANCE
            balancer.repair_breaches(scenario, values)
          else
            []
          end

        return imbalance_error(balancer, values) if breaches.empty?

        "#{balancer.group_name} group sums to #{values.values.sum} and cannot be " \
          "repaired: #{breaches.map { |b| breach_message(b) }.join('; ')}"
      end

      def imbalance_error(balancer, values)
        info = values.map { |key, value| "#{key}=#{value}" }.join(' ')

        "#{balancer.group_name} group does not balance: group sums to " \
          "#{values.values.sum} using #{info}"
      end

      def breach_message(breach)
        "rescaling #{breach[:key]} to #{breach[:value]} would move it outside " \
          "its bounds (#{breach[:min]}..#{breach[:max]})"
      end
    end
  end
end
