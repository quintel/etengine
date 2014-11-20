module Qernel::Plugins
  module MeritOrder
    extend ActiveSupport::Concern

    def use_merit_order_demands?
      future? && self[:use_merit_order_demands].to_i == 1
    end

    def merit
      @merit ||= Merit::Order.new
    end
  end # MeritOrder
end


