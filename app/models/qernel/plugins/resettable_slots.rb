module Qernel::Plugins
  class ResettableSlots
    include Plugin

    after :calculation, :reset_slots_to_zero

    def reset_slots_to_zero
      @graph.nodes.each do |node|
        node.slots.each do |slot|
          if slot.reset_to_zero == true
            slot.conversion = 0.0

            slot.edges.each do |edge|
              edge.share = 0.0
              edge.value = 0.0
            end
          end # if
        end # node.slots.each
      end # nodes.each
    end
  end # ResettableSlots
end # Qernel::Plugins
