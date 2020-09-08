# frozen_string_literal: true

module Qernel
  module NodeApi
    # Dynamically creates useful methods on relating to carrier inputs and outputs.
    module CarrierMethods
      # Extracted into a method, because we have a circular dependency in specs
      # Carriers are not imported, so when initializing all those methods won't get
      # loaded. So this way we can load later.
      def self.create_methods_for_each_carrier(carrier_names)
        carrier_names.each do |carrier|
          carrier_key = carrier.to_sym

          define_method "demand_of_#{carrier}" do
            output_of_carrier(carrier_key) || 0.0
          end

          define_method "supply_of_#{carrier}" do
            input_of_carrier(carrier_key) || 0.0
          end

          define_method "input_of_#{carrier}" do
            input_of_carrier(carrier_key) || 0.0
          end

          define_method "output_of_#{carrier}" do
            output_of_carrier(carrier_key) || 0.0
          end

          define_method "primary_demand_of_#{carrier}" do
            primary_demand_of_carrier(carrier_key) || 0.0
          end

          %i[input output].each do |direction|
            define_method "#{carrier}_#{direction}_edge_share" do
              if (slot = node.send(direction, carrier_key))
                if (edge = slot.edges.first)
                  edge.send('share') || 0.0
                else
                  0.0
                end
              else
                0.0
              end
            end

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{carrier}_#{direction}_conversion
                carrier_direction_conversion(#{carrier.inspect}, #{direction.inspect})
              end
            RUBY
          end
        end
      end

      create_methods_for_each_carrier(Etsource::Dataset::Import.new('nl').carrier_keys)

      private

      def carrier_direction_conversion(carrier_key, direction)
        fetch(:"#{carrier_key}_#{direction}_conversion") do
          slot = direction == :input ? node.input(carrier_key) : node.output(carrier_key)
          slot&.conversion || 0.0
        end
      end
    end
  end
end
