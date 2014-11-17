module Qernel::Plugins
  module MeritOrder
    extend ActiveSupport::Concern

    def use_merit_order_demands?
      self[:use_merit_order_demands].to_i == 1
    end

    def merit
      future? && (@merit ||= Merit::Order.new)
    end
  end # MeritOrder
end


