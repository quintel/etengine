# frozen_string_literal: true

module Qernel
  module FeverFacade
    class ProducerAdapter < Adapter
      # Contains methods for computing the producer carrier, and provides
      # methods for dealing with carriers.
      module CarrierHelpers
        # Public: Returns the Fever producer which takes the given carrier key
        # as input, or nil if the adapter does not contains such a producer.
        def producer_for_carrier(carrier)
          participant.producer if input?(carrier)
        end

        # Public: Returns if the named carrier (a Symbol) is one of the inputs
        # to the node used by this adapter.
        #
        # Returns true or false.
        def input?(carrier)
          !@node.node.input(carrier).nil?
        end

        # Public: Creates a callable which takes a frame number and returns how
        # much demand there is for a given carrier in that frame. Accounts for
        # output losses.
        #
        # Returns a proc.
        def demand_callable_for_carrier(carrier)
          if (producer = producer_for_carrier(carrier))
            efficiency = output_efficiency
            ->(frame) { producer.source_at(frame) / efficiency }
          else
            ->(*) { 0.0 }
          end
        end

        private

        # Internal: Determines the name of the main input carrier to the
        # node.
        def input_carrier
          return @input_carrier if @input_carrier

          slots =
            @node.node.inputs.reject do |slot|
              slot.carrier.key == :ambient_heat
            end

          if slots.length != 1
            raise 'Cannot determine input carrier for Fever producer: ' \
                  "#{@node.key}"
          end

          @input_carrier = slots.first.carrier.key
        end
      end
    end
  end
end
