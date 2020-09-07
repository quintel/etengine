# frozen_string_literal: true

module Qernel
  # Edge is split into two parts: the Edge class, which is used to describe the structure of the
  # graph, and how the edge connects two nodes, and the API which supports calculations and
  # attributes specific to the Energy and Molecule graphs.
  module EdgeApi
    module_function

    # Public: Creates an appropriate EdgeApi instance for the Edge.
    #
    # Returns an EdgeApi
    def from_edge(edge)
      (edge.graph_name == :molecules ? Base : Energy).new(edge)
    end
  end
end
