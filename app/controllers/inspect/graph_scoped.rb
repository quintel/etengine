# frozen_string_literal: true

module Inspect
  # A module which may be included in a controller to indicate that one of the controller params is
  # a graph name.
  #
  # Asserts that the graph name is valid, and provides useful helpers for accessing the graph.
  module GraphScoped
    extend ActiveSupport::Concern

    # A list of valid graph names.
    GRAPHS = %w[energy molecules].freeze

    included do
      before_action :assert_valid_graph
      helper_method :present_graph
      helper_method :future_graph
    end

    private

    def assert_valid_graph
      render_not_found unless GRAPHS.include?(params[graph_parameter_name])
    end

    def present_graph
      if params[:graph_name] == 'molecules'
        @gql.present.molecules
      else
        @gql.present.graph
      end
    end

    def future_graph
      if params[:graph_name] == 'molecules'
        @gql.future.molecules
      else
        @gql.future.graph
      end
    end

    def graph_parameter_name
      :graph_name
    end
  end
end
