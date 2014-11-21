module Qernel::Plugins
  class ResettableSlots
    include Plugin

    after :calculation, :reset_slots_to_zero

    def reset_slots_to_zero
      @graph.converters.each do |converter|
        converter.slots.each do |slot|
          if slot.reset_to_zero == true
            slot.conversion = 0.0

            slot.links.each do |link|
              link.share = 0.0
              link.value = 0.0
            end
          end # if
        end # converter.slots.each
      end # converters.each
    end
  end # ResettableSlots
end # Qernel::Plugins
