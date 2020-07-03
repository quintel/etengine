# frozen_string_literal: true

module Qernel
  # Interface for a Qernel::Graph object to the outside world (GQL). The purpose was to proxy the
  # access to the Qernel objects, so that in future it might be easier to implement the graph for
  # instance in another language (C, Java, Scala).
  #
  # The GraphApi also includes a couple of more complicated queries that would be too cumbersome for
  #  a GQL query.
  #
  module GraphApi
    module_function

    # Public: Creates a new GraphApi for the given `graph`.
    #
    # Based on the graph attributes, an appropriate GraphApi class is instantiated and returned.
    #
    # Returns a GraphApi::Common.
    def from_graph(graph)
      GraphApi::Energy.new(graph)
    end
  end
end
