module Qernel
  module Causality
    # Creates a demand curve for use in the Merit order by combining a total
    # demand with a mix of curve "components" which should be mixed together in
    # a share defined by the user.
    #
    # For example
    #   AggregateCurve.build(10_000, profile_one => 0.3, profile_two => 0.7)
    #   # => Merit::Curve
    #
    module AggregateCurve
      module_function

      # Internal: Sums one or more profiles using the given profile mix.
      #
      # Returns Merit::Curve.
      def build(mix)
        return zeroed_profile if mix.empty?
        return mix.keys.first if mix.length == 1

        Merit::CurveTools.add_curves(
          balanced_mix(mix)
            .map { |prof, share| prof * share if share.positive? }
            .compact
        )
      end

      # Public: Returns a profile of all zeroes.
      def zeroed_profile
        Merit::Curve.new(Array.new(8760, 0.0))
      end

      # Internal: Ensures that a mix of profiles sum to 1.0.
      #
      # Returns a hash.
      def balanced_mix(mix)
        sum = mix.values.sum

        return mix if (1.0 - sum).abs < 1e-5

        # The mix of profiles does not come to (nearly) 1.0, therefore we
        # rebalance the mix to ensure we have a useable profile.
        mix.each_with_object({}) do |(key, value), balanced|
          balanced[key] = value / sum
        end
      end

      private_class_method :balanced_mix
    end
  end
end
