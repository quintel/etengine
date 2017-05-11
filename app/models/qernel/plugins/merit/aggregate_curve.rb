module Qernel::Plugins
  module Merit
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

      def build(demand, curves)
        return zeroed_profile if demand.zero? || curves.empty?

        aggregate(balanced_mix(curves)) * demand
      end

      # Internal: Given a hash of load profile keys, returns a new hash where
      # each key is the appropriate LoadProfile object. Missing load profiles
      # are omitted.
      #
      # Returns a hash.
      def mix(dataset, curves)
        curves.each_with_object({}) do |(key, share), data|
          path = dataset.load_profile_path(key)
          next unless path.file?

          data[::Merit::LoadProfile.load(path)] = share
        end
      end

      # Internal: Sums one or more profiles using the given profile mix.
      #
      # Returns Merit::Curve.
      def aggregate(mix)
        length = mix.keys.first.length

        return mix.values.first if length == 1

        mix.reduce(::Merit::Curve.new([], length)) do |memo, (prof, share)|
          share > 0 ? memo + (prof * share) : memo
        end
      end

      private_class_method :aggregate

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

      def zeroed_profile
        ::Merit::Curve.new(Array.new(8760, 0.0))
      end

      private_class_method :zeroed_profile
    end
  end
end

