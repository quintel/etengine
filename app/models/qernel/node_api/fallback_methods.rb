# frozen_string_literal: true

module Qernel
  module NodeApi
    # Implements `method_missing` for various occasionally-used helper methods in GQL.
    module FallbackMethods
      # Creates a method during run time if method_missing
      def self.create_share_of_node_method(node_key)
        key = node_key.to_sym
        define_fallback_method "share_of_#{key}" do
          ol = node.output_edges.detect { |l| l.lft_node.key == key }
          ol&.share
        end
      end

      # Creates a method during run time if method_missing and returns the value.
      def self.create_share_of_node_method_and_execute(caller, node_key)
        create_share_of_node_method(node_key)
        caller.send("share_of_#{node_key}")
      end

      # Creates a method during run time if method_missing.
      def self.create_input_edge_method(method_id, carrier_name, side, method)
        if /^(.*)_(constant|share|inversedflexible|flexible)$/.match?(carrier_name)
          carrier_name, edge_type =
            carrier_name.match(/^(.*)_(constant|share|inversedflexible|flexible)$/).captures

          edge_type = 'inversed_flexible' if edge_type == 'inversedflexible'
        end
        define_fallback_method method_id do
          if (slot = node.send(side, carrier_name.to_sym))
            edge = if edge_type.nil?
              slot.edges.first
            else
              slot.edges.detect { |l| l.send("#{edge_type}?") }
            end

            edge&.send(method)
          end
        end
      end

      # Creates a method during run time if method_missing and returns the value
      def self.create_input_edge_method_and_execute(caller, method_id, carrier_name, side, method)
        create_input_edge_method(method_id, carrier_name, side, method)
        caller.send(method_id)
      end

      def respond_to_missing?(name, include_private = false)
        name = name.to_s

        name.match?(/^.*_(input|output)_edge_(share|value)$/) ||
          name.start_with?('share_of_') ||
          name.start_with?('cost_') ||
          name.start_with?('primary_demand') ||
          name.start_with?('demand_of_') ||
          name.start_with?('dependent_supply') ||
          name.start_with?('final_demand') ||
          super
      end

      def method_missing(method_id, *arguments)
        ActiveSupport::Notifications.instrument('gql.debug', "NodeApi:method_missing #{method_id}")

        method_id_s = method_id.to_s

        # electricity_
        if (m = /^(.*)_(input|output)_edge_(share|value)$/.match(method_id_s))
          carrier_name, side, method = m.captures
          self.class.create_input_edge_method_and_execute(
            self, method_id, carrier_name, side, method
          )
        elsif (m = /^share_of_(\w*)$/.match(method_id_s)) && (match = m.captures.first)
          self.class.create_share_of_node_method_and_execute(self, match)
        elsif (m = /^cost_(\w*)$/.match(method_id_s)) && (method_name = m.captures.first)
          send(method_name)
        elsif /^primary_demand(\w*)$/.match?(method_id_s)
          node.send(method_id, *arguments)
        elsif /^demand_of_(\w*)$/.match?(method_id_s)
          node.send(method_id, *arguments)
        elsif /^dependent_supply(\w*)$/.match?(method_id_s)
          node.send(method_id, *arguments)
        elsif /^final_demand(\w*)$/.match?(method_id_s)
          node.send(method_id, *arguments)
        else
          Rails.logger.info("NodeApi#method_missing: #{method_id}")
          super(method_id)
        end
      end
    end
  end
end
