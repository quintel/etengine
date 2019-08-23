module Qernel
  module MeritFacade
    module CurvePeakFinder
      module_function

      # The hour in which night becomes day.
      DAY_START = 6

      # The hour in which day again becomes night.
      NIGHT_START = 18

      # Winter starts at the beginning of the year and ends in this frame (3
      # months in).
      SUMMER_START = 8760 / 4

      # Winter resumes at this frame (9 months in) and continues to the end of
      # the year.
      WINTER_START = SUMMER_START * 3

      # Public: Given a load curve, returns a hash containing the peak load for
      # summer daytime `:sd`, summer evening `:sd`, winter daytime `:wd`, and
      # winter evening `:we`.
      #
      # Returns a hash.
      def peaks(curve)
        if curve.length != 8760
          raise("Curve must contain 8760 frames; got #{curve.length}")
        end

        curve
          .each_with_object(wd: 0.0, we: 0.0, sd: 0.0, se: 0.0)
          .with_index do |(value, data), frame|
            key = key_for_frame(frame)
            data[key] = value if value > data[key]
          end
      end

      # Internal: Determines if the given frame number is summer or winter,
      # evening or daytime.
      #
      # Returns a Symbol.
      def key_for_frame(frame)
        if frame < SUMMER_START || frame >= WINTER_START
          daytime?(frame) ? :wd : :we
        else
          daytime?(frame) ? :sd : :se
        end
      end

      private_class_method :key_for_frame

      def daytime?(frame)
        (frame % 24) >= DAY_START && (frame % 24) < NIGHT_START
      end

      private_class_method :daytime?
    end # CurvePeakFinder
  end # Merit
end # Qernel::Plugins
