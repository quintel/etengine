# frozen_string_literal: true

module Qernel
  module GraphApi
    # Methods common to all types of GraphApi.
    module Common
      include DatasetAttributes

      def self.included(base)
        base.class_eval do
          # Public: Returns the Graph represented by this GraphApi.
          attr_reader :graph
        end
      end

      delegate(
        :area,
        :carrier,
        :dataset_attributes,
        :dataset_key,
        :number_of_years,
        :year,
        to: :graph
      )

      # @param graph [Qernel::Graph]
      def initialize(graph)
        @graph = graph
      end

      def node(key)
        graph.node(key).query
      end
    end
  end
end
