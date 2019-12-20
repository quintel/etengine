# frozen_string_literal: true

module Etsource
  # Imports a list of reconciliation carriers and nodes from Atlas and ETSource.
  module Reconciliation
    class << self
      include Enumerable

      def each
        return block_for(:each) unless block_given?

        carrier_node_map.each do |carrier, node_map|
          yield carrier, node_map
        end
      end

      def supported_carrier?(carrier)
        carrier_list.include?(carrier.to_sym)
      end

      private

      # Imports a list of carriers and nodes which belong to a reconciliation
      # calculation.
      #
      # For example:
      #
      #   Etsource::Reconciliation.import
      #   # => {
      #   #   hydrogen: { consumer: [:a, :b], producer: [:c, :d], storage: [:e] }
      #   #   network_gas: { consumer: [:x], producer: [ :y], storage: [:z] }
      #   # }
      def carrier_node_map
        Rails.cache.fetch('reconciliation_hash') do
          carrier_list.each_with_object({}) do |carrier, data|
            data[carrier] = import_carrier(carrier)
          end.freeze
        end
      end

      # Internal: Imports the list of nodes keys applicable to reconciliation of
      # the named carrier.
      def import_carrier(carrier)
        data =
          Atlas::Node.all.each_with_object({}) do |node, hash|
            config = node.public_send(carrier)
            next unless config

            hash[config.type] ||= []
            hash[config.type].push(node.key)
          end

        data.transform_values(&:freeze)
        data.freeze
      end

      # Internal: An array of symbols matching carrier/attribute names which
      # should have a reconciliation carrier.
      def carrier_list
        Rails.cache.fetch('reconciliation_carriers') do
          Atlas::Node.attribute_set.select do |attribute|
            attribute.primitive == Atlas::NodeAttributes::Reconciliation
          end.map(&:name)
        end
      end
    end
  end
end
