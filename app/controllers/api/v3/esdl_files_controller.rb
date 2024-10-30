# frozen_string_literal: true

module Api
  module V3
    # Provides the ability to attach and download an esdl file to/from a scenario.
    class EsdlFilesController < BaseController
      include UsesScenario

      before_action :ensure_upload_is_file, only: :update
      before_action :ensure_reasonable_file_size, only: :update
      before_action :set_current_scenario

      # Sends data on the current attached esdl file for the scenario, or an empty object if none is
      # set. When the parameter download is set, also sends the file.
      #
      # GET /api/v3/scenarios/:scenario_id/esdl_file
      def show
        render json: {} and return unless esdl_file

        render json: EsdlFileSerializer.new(esdl_file, params[:download] == 'true').as_json
      end

      # Creates or updates an attached esdl file for a scenario.
      #
      # PUT /api/v3/scenarios/:scenario_id/esdl_file
      def update
        upload = params.require(:file)
        handler = setup_handler(upload)

        if handler.valid?
          handler.call
          render json: {}, status: 202
        else
          render json: { errors: handler.errors }, status: 422
        end
      end

      private

      def esdl_file
        @esdl_file ||= @scenario.attachment('esdl_file')
      end

      def setup_handler(upload)
        FileUploadHandler.new(
          upload,
          'esdl_file',
          @scenario
        )
      end

      # Asserts that the user uploaded a file, and not a string or other object.
      def ensure_upload_is_file
        return if params.require(:file).respond_to?(:tempfile)

        render(
          json: {
            errors: ['"file" was not a valid multipart/form-data file'],
            error_keys: [:not_multipart_form_data]
          },
          status: 422
        )
      end

      def ensure_reasonable_file_size
        return unless params.require(:file).size > 5.megabyte

        render(
          json: {
            errors: ['ESDL file should not be larger than 5MB'],
            error_keys: [:file_too_large]
          },
          status: 422
        )
      end
    end
  end
end
