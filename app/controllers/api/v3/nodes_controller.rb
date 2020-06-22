module Api
  module V3
    class NodesController < BaseController
      before_action :set_current_scenario
      before_action :find_node, :only => :show

      # GET /api/v3/nodes/:id
      #
      # Returns the node details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code. Since the
      # nodes now aren't stored in a db table we use the key rather than
      # the id
      #
      def show
        render :json => @node
      end

      # POST /api/v3/nodes/:id/stats
      #
      # Returns a breakdown of some node statistics used by ETLoader to
      # calculate network loads in testing grounds.
      #
      # As node keys can be quite long, and the request may include tens of
      # node keys, the request is to be sent as POST with a JSON payload
      # with the following schema:
      #
      # { "keys": {
      #   "key1": [ .. ],
      #   "key2": [ .. ],
      #   "...",
      #   "keyN": [ .. ]
      # }
      def stats
        keys = permitted_params.to_h.fetch(:keys)
        gql  = @scenario.gql(prepare: true)

        render json: { nodes: Hash[keys.map do |key, graph_attributes|
          [ key, NodeStatsPresenter.new(key.to_sym, gql, graph_attributes) ]
        end] }
      end

      # returns the node topology coordinates, using the old
      # node_positions table
      #
      def topology
        topology = TopologyPresenter.new(@scenario)
        render :json => topology
      end

      private

      def find_node
        key = params[:id].presence&.to_sym
        @node = NodePresenter.new(key, @scenario)
      rescue StandardError => e
        render_not_found(errors: [e.message])
      end

      def permitted_params
        params.permit(:scenario_id, keys: {})
      end
    end
  end
end
