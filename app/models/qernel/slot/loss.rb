module Qernel
  # A customised Elastic slot used for dynamically calculating loss. Ignores
  # :coupling_carrier slots when calculating.
  #
  class Slot::Loss < Slot::Elastic
    # Public: Returns the sibling slots to be considered when calculating
    # loss.
    #
    # Returns an array of Slots
    def inelastic_siblings
      super.reject { |slot| slot.carrier.coupling_carrier? }
    end
  end # Slot::Loss
end # Qernel
