# frozen_string_literal: true

require 'forwardable'

module Qernel
  module EdgeApi
    # A base class implementing behaviour for the EdgeApi. This behaviour is shared between all
    # edges and does not contain behaviour specific to a graph.
    class Base
      extend Forwardable
      include DatasetAttributes

      dataset_accessors Qernel::Edge::DATASET_ATTRIBUTES

      def_delegators(
        :@edge,
        :carrier,
        :constant?,
        :demand,
        :dependent?,
        :energetic?,
        :flexible?,
        :input,
        :inversed_flexible?,
        :key,
        :lft_node,
        :output,
        :parent_share,
        :rgt_node,
        :sector,
        :share?
      )

      Etsource::Dataset::Import.new('nl').carrier_keys.each do |carrier_key|
        def_delegator :@edge, :"#{carrier_key}?"
      end

      # Returns the Edge which this EdgeApi wraps.
      attr_reader :edge

      # Returns the unique key representing the collection where the edge data is found in the
      # dataset. This always matches the edge, ensuring that both are backed by the same data
      # structure.
      attr_reader :dataset_group

      # Returns the unique key representing the edge in the dataset. This always matches the edge,
      # ensuring that both are backed by the same data structure.
      attr_reader :dataset_key

      # Attributes required by DatasetAttributes.
      attr_accessor :graph

      # Public: Defines a method on the Edge which, when called, will call the
      # method of the same name on the parent node's NodeApi, reducing
      # the value according to the slot conversion and parent share.
      #
      # Returns nothing.
      def self.delegated_calculation(name, lossless = false)
        define_method(name) do |*args|
          delegated_calculation(name, lossless, *args)
        end
      end

      def initialize(edge)
        @edge = edge
        @dataset_key = edge.dataset_key
        @dataset_group = edge.dataset_group
      end

      # Internal: Delegates a calculation to the parent node NodeApi, reducing the returned value in
      # accordance with the slot conversion and edge share.
      #
      # calculation - The method to be called on the NodeApi
      # lossless    - Adjust the value returned by the NodeApi to compensate for the output of
      #               loss from the converter (i.e. if the value returned by the NodeAPi is 10 and
      #               the loss accounts for 20% of the output, the final return value will be 12.5).
      # *args       - Arguments passed in when the delegated method was called.
      #
      # Returns a number, or nil if the calculation returned nil.
      def delegated_calculation(calculation, lossless = false, *args)
        value = rgt_node.query.public_send(calculation, *args)

        if value
          loss_comp = lossless ? rgt_node.query.loss_compensation_factor : 1.0
          value * (output.conversion * loss_comp) * @edge.parent_share
        end
      end

      # Internal: Micro-optimization which improves the performance of
      # Array#flatten when the array contains Edges.
      #
      # See http://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
      def to_ary
        nil
      end

      def inspect
        "#<#{self.class.name} #{@edge.key}>"
      end
    end
  end
end
