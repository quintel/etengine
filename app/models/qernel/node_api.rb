# frozen_string_literal: true

module Qernel
  # Node is split into two parts: the Node class, which is used to describe the structure of the
  # graph, and how the node is related to others, and the API which supports a wide range of
  # calculations and attributes about the node.
  #
  # While all nodes in the graph are a Node, they may have different API classes depending on their
  # behaviour. NodeApi contains classes and modules which implement the API.
  module NodeApi
    module_function

    # Returns a NodeApi instance based on the given Node.
    #
    # Most nodes will get a NodeApi, but for some it makes sense to
    # get a DemandDriven API instead.
    #
    # @param [Qernel::Node] node
    #   A node instance for which you want a NodeApi.
    #
    # @return [Qernel::NodeApi]
    #   The appropriate NodeApi subclass for the node.
    #
    def from_node(node)
      if node.groups.include?(:demand_driven)
        NodeApi::DemandDrivenNodeApi.new(node)
      elsif node.groups.include?(:inheritable_nou)
        NodeApi::InheritableNouNodeApi.new(node)
      else
        NodeApi::Base.new(node)
      end
    end
  end
end
