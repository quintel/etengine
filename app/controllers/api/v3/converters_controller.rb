module Api
  module V3
    class ConvertersController < BaseController
      before_filter :set_current_scenario, :only => :show
      before_filter :find_converter, :only => :show

      # GET /api/v3/converters/:id
      #
      # Returns the converter details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code. Since the
      # converters now aren't stored in a db table we use the key rather than
      # the id
      #
      def show
        render :json => @converter_present.class
      end

      private

      def find_converter
        # the current converters_controller implementation pulls is
        # all the graphs, current and future. Let's find a clean way
        # to fetch it. This action is currently broken
        key = params[:id].to_sym rescue nil
        # ugly!
        @converter_present = @gql.present_graph.graph.converter(key) rescue nil
        @converter_future  = @gql.future_graph.graph.converter(key) rescue nil
        if @converter_present.nil? || @converter_future.nil?
          render :json => {:errors => ["Converter not found"]}, :status => 404 and return
        end
      end
    end
  end
end
