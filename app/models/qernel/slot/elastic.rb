module Qernel
  # Represents slots whose +conversion+ adjusts dynamically to fill whatever
  # remains from the other slots on the converter. This ensures that the
  # cumulative conversion of all the slots add up to 1.0.
  #
  # Used for:
  #
  #   * Output slots whose carrier is "loss".
  #
  class Slot::Elastic < Slot

    # Dynamically calculates +conversion+ so that all of the slots sum to 1.0.
    def conversion
      function(:conversion) do
        others = siblings.sum(&:conversion)

        # Don't break the laws of thermodynamics; conversion may not be
        # negative.
        others > 1.0 ? 0.0 : 1.0 - others
      end
    end

  end # Slot::Elastic
end # Qernel
