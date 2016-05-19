module Api
  module V3
    class ConvertersController < BaseController
      before_filter :set_current_scenario
      before_filter :find_converter, :only => :show

      # GET /api/v3/converters/:id
      #
      # Returns the converter details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code. Since the
      # converters now aren't stored in a db table we use the key rather than
      # the id
      #
      def show
        render :json => @converter
      end

      # POST /api/v3/converters/:id/stats
      #
      # Returns a breakdown of some converter statistics used by ETLoader to
      # calculate network loads in testing grounds.
      #
      # As converter keys can be quite long, and the request may include tens of
      # converter keys, the request is to be sent as POST with a JSON payload
      # with the following schema:
      #
      # { "keys": {
      #   "key1": [ .. ],
      #   "key2": [ .. ],
      #   "...",
      #   "keyN": [ .. ]
      # }
      def stats
        keys = params.require(:keys)
        gql  = @scenario.gql(prepare: true)

        render json: { nodes: Hash[keys.map do |key, graph_attributes|
          [ key, ConverterStatsPresenter.new(key.to_sym, gql, graph_attributes) ]
        end] }
      end

      # returns the converter topology coordinates, using the old
      # converter_positions table
      #
      def topology
        topology = TopologyPresenter.new(@scenario)
        render :json => topology
      end

      private

      def find_converter
        key = params[:id].to_sym rescue nil
        @converter = ConverterPresenter.new(key, @scenario)
      rescue Exception => e
        render :json => {:errors => [e.message]}, :status => 404 and return
      end
    end
  end
end
