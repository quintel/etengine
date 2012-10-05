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
        render :json => @converter
      end

      # returns the converter topology coordinates, using the old
      # converter_positions table
      #
      def topology
        render :json => ConverterPosition.not_hidden.map {|c|
          { key: c.converter_key, x: c.x, y: c.y }
        }
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
