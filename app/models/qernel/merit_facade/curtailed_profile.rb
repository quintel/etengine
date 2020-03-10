# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Given a profile and a curtailment factor, builds a new profile with peak
    # values curtailed.
    #
    # For example, if the peak value in the curve is 100, and curtailment is set
    # to 0.25 (25%), and value in the `useable_profile` will be saturated at 75.
    class CurtailedProfile
      def initialize(profile, curtailment = 0.0)
        @profile = profile
        @curtailment = curtailment
      end

      # Public: The profile to be used to calculate a demand curve; values above
      # the saturation point are curtailed.
      def useable_profile
        return @profile if @curtailment.zero?
        return zeroed_profile if @curtailment >= 1.0

        sat = saturation_point

        @profile.class.new(@profile.map do |value|
          value > sat ? sat : value
        end)
      end

      # Public: Given the original uncurtailed demand, computes the curve
      # describing how much energy was curtailed in each frame.
      def curtailment_curve(demand)
        return zeroed_profile if @curtailment.zero?

        useable_profile.map.with_index do |curtailed_factor, frame|
          uncurtailed = demand * @profile[frame]
          uncurtailed - (demand * curtailed_factor)
        end
      end

      private

      def saturation_point
        max = @profile.max
        max - max * @curtailment
      end

      def zeroed_profile
        @profile.class.new(Array.new(@profile.length, 0.0))
      end
    end
  end
end
