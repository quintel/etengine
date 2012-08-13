module Qernel::Plugins
  module ResettableSlots
    extend ActiveSupport::Concern

    included do |variable|
      set_callback :calculate, :after,  :reset_slot_to_zero
    end

    def reset_slot_to_zero
      instrument("qernel.calculate_max_demand_recursive") do
        converters.each do |c|
          c.slots.each do |slot|
            if slot.reset_to_zero == true
              slot.conversion = 0.0 
              slot.links.each do |link|
                link.share = 0.0
                link.value = 0.0
              end
            end # if
          end # c.slots.each
        end # converters.each
      end # instrument
    end # def

  end
end
