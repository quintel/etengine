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

    # Creates a new Elastic slot.
    #
    # @raise [Qernel::Slot::Elastic::TooManyElasticSlots]
    #   Raised if the converter already has an elastic slot with the same
    #   direction.
    #
    def initialize(*)
      super

      if siblings.any? { |s| s.kind_of?(Slot::Elastic) }
        raise TooManyElasticSlots.new(self)
      end
    end

    # Dynamically calculates +conversion+ so that all of the slots sum to 1.0.
    def conversion
      function(:conversion) do
        others = siblings.sum(&:conversion)

        # Don't break the laws of thermodynamics; conversion may not be
        # negative.
        others > 1.0 ? 0.0 : 1.0 - others
      end
    end

    # Raised when trying to add a second elastic slot to a converter.
    class TooManyElasticSlots < RuntimeError
      def initialize(slot)
        @slot = slot
      end

      def message
        other = @slot.siblings.detect do |sibling|
          sibling.kind_of?(Slot::Elastic)
        end

        <<-MESSAGE.squish!
          Converter #{ @slot.converter.inspect } already has an elastic slot
          (#{ other.inspect }); you cannot add #{ @slot.inspect }.
        MESSAGE
      end
    end

  end # Slot::Elastic
end # Qernel
