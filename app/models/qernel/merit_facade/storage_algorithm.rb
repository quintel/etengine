# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Contains the optimization algorithm for batteries. Given a residual load curve, battery
    # capacity and volume, this will return the amount of energy stored in the battery for each
    # hour which flattens the load curve as much as possible.
    module StorageAlgorithm
      module_function

      # Stores each hour and its current value.
      Frame = Struct.new(:index, :value)

      # Runs the optimization. Returns the energy stored in the battery in each hour.
      #
      # Arguments:
      # data               - The residual load curve
      # charging_target    - Curve describing the desired charging in each hour
      # discharging_target - Curve describing the desired discharging in each hour
      #
      # Keyword arguments:
      # volume      - The volume of the battery in MWh.
      # capacity    - The volume of the battery in MW.
      # lookbehind  - How many hours the algorithm can look into the past to search for the minimum.
      #
      # Returns an array containing the amount stored in the battery in each hour.
      def run(
        data,
        capacity:,
        lookbehind: 72,
        volume:
      )
        # Creates curves which describe the maximum amount by which the battery can charge or
        # discharge in each hour.
        charging_target = Numo::DFloat.cast([capacity] * data.length)
        discharging_target = charging_target.dup

        # All values for the year converted into a frame.
        frames = data.to_a.map.with_index { |value, index| Frame.new(index, value) }

        # Contains all hours where there is room to discharge, sorted in ascending order (hour of
        # largest value is last).
        charge_frames = frames.select { |f| discharging_target[f.index].positive? }.sort_by(&:value)

        # Keeps track of how much energy is stored in each hour.
        reserve = Numo::DFloat.zeros(data.length)

        while charge_frames.length.positive?
          max_frame = charge_frames.pop

          # Eventually will contain the amount of energy to be charged in the min frame and
          # discharged at the max frame.
          available_energy = discharging_target[max_frame.index]

          # The frame cannot be discharged any further.
          next if available_energy.zero?

          # Only charge from an hour whose value is 95% or less than the max frame value.
          desired_low = max_frame.value * 0.95

          # Contains the hour within the lookbehind period with the minimum value.
          min_frame = nil

          (max_frame.index - 1).downto(max_frame.index - 1 - lookbehind) do |min_index|
            # We've reached a frame where the battery is full; therefore neither it nor any earlier
            # frame will be able to charge.
            break if reserve[min_index] >= volume

            current = frames[min_index]

            # Limit charging by the remaining volume in the frame.
            available_energy = [volume - reserve[min_index], available_energy].min

            next unless available_energy.positive? &&
              charging_target[current.index].positive? &&
              (!min_frame || current.value < min_frame.value) &&
              current.value < desired_low

            min_frame = current
          end

          # We now have either the min frame, or nil in whihc case no optimization can be performed
          # on the max frame.
          next if min_frame.nil?

          # The amount of energy to be charged in the min frame and discharged at the max frame.
          # Limited to 1/4 of the difference in order to assign frames back on to the stack to so
          # that their energy may be more fairly shared with other nearby frames.
          available_energy = [(max_frame.value - min_frame.value) / 4, available_energy].min

          next if available_energy < 1e-5

          # Add the charge and discharge to the reserve.
          if min_frame.index > max_frame.index
            # Wrapped from end of the year to the beginning
            reserve[min_frame.index..] += available_energy
            reserve[0...max_frame.index] += available_energy if max_frame.index.positive?
          else
            reserve[min_frame.index...max_frame.index] += available_energy
          end

          min_frame.value += available_energy
          max_frame.value -= available_energy

          charging_target[min_frame.index] -= available_energy
          discharging_target[min_frame.index] = 0 # Frame is no longer allowed to discharge.

          discharging_target[max_frame.index] -= available_energy
          charging_target[max_frame.index] = 0 # Frame is no longer allowed to charge.

          next unless discharging_target[max_frame.index].positive?

          # The max frame can be further discharged. Add it back on the stack.
          insert_at = charge_frames.bsearch_index { |v| v.value > max_frame.value }

          if insert_at
            charge_frames.insert(insert_at - 1, max_frame)
          else
            charge_frames.push(max_frame)
          end
        end

        reserve
      end
    end
  end
end
