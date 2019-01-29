module Etsource
  class Dataset
    # Wraps an insulation cost CSV file from ETSource to ensure that lookups to
    # non-existent keys return sensible values.
    #
    # For example, looking up a change from insulation level 5 to insulation
    # level 90, when when maximum level is 70 will return the appropriate value
    # for 5 -> 70.
    class InsulationCostMap
      # Describes the minimum and maximum permitted values for the present or
      # future.
      Constraint = Struct.new(:min, :max) do
        # Public: Given a level, ensures that it does not exceed the values
        # permitted by the constraint. Values which are too large or too small
        # will be constrained.
        #
        # Returns a Numeric.
        def constrain(level)
          level = level.to_i

          return min if level < min
          return max if level > max

          level
        end
      end

      # A constraint that does nothing.
      class NullConstraint
        def constrain(level)
          level
        end
      end

      # Public: Creates a new InsulationCostMap, wrapping around an
      # Atlas::CSVDocument.
      #
      # Returns an InsulationCostMap
      def initialize(csv)
        @csv = csv
      end

      # Public: Looks up the cost of change from insulation `from_level` to
      # insulation `to_level`.
      def get(from_level, to_level)
        @csv.get(
          present_constraint.constrain(from_level),
          future_constraint.constrain(to_level)
        )
      end

      private

      def present_constraint
        @present_constraint ||= constraint_for(@csv.row_keys)
      end

      def future_constraint
        @future_constraint ||= constraint_for(@csv.column_keys[1..-1])
      end

      def constraint_for(keys)
        begin
          min_key = Integer(keys.first.to_s)
          max_key = Integer(keys.last.to_s)
        rescue TypeError, ArgumentError
          # Non-numeric level keys: probably the new build CSV
          return NullConstraint.new
        end

        Constraint.new(min_key, max_key)
      end
    end
  end
end
