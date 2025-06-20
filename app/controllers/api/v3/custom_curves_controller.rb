# frozen_string_literal: true

module Api
  module V3
    # Provides the ability to upload or remove a custom curve from a scenario.
    #
    # This controller uses the UserCurve model, which stores curves in the database using
    # MessagePack-encoded Merit::Curve objects.
    class CustomCurvesController < BaseController
      include ActionController::MimeResponds
      include UsesScenario

      before_action :ensure_valid_curve_name, except: :index
      before_action :ensure_upload_is_file, only: :update
      before_action :ensure_reasonable_file_size, only: :update
      before_action :ensure_curve_set, only: %i[show destroy]

      # Sends information about all custom curves attached to the scenario.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves
      def index
        result = CurveHandler::Services::IndexService.new(scenario, params).call
        render json: result.series
      end

      # Sends the curve metadata or raw CSV data for a curve stored in the scenario.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves/:name
      def show
        result = CurveHandler::Services::ShowService.new(scenario, params).call

        if request.format.csv?
          send_data result.csv_data,
                    type: 'text/csv',
                    filename: result.filename
        else
          render json: result.json
        end
      end

      # Creates or updates a custom curve for a scenario.
      #
      # PUT /api/v3/scenarios/:scenario_id/custom_curves/:name
      def update
        result = CurveHandler::Services::UpdateService.new(scenario, params, metadata_parameters).call

        if result.errors.present?
          render json: { errors: result.errors, error_keys: result.error_keys },
                status: :unprocessable_entity
        else
          render json: result.json
        end
      end

      # Removes an existing custom curve from a scenario.
      #
      # DELETE /api/v3/scenarios/:scenario_id/custom_curves/:id
      def destroy
        CurveHandler::Services::DestroyService.new(scenario, params).call
        head :no_content
      end

      private

      # Extracts metadata from the params, if present.
      def metadata_parameters
        return {} unless params[:metadata]

        params.require(:metadata).permit(
          :source_scenario_id,
          :source_scenario_title,
          :source_saved_scenario_id,
          :source_dataset_key,
          :source_end_year
        )
      end

      # Asserts that the named curve exists in the configuration.
      def ensure_valid_curve_name
        return if CurveHandler::Config.key?(params[:id])

        render(
          json: { errors: ["No such custom curve: #{params[:id].inspect}"] },
          status: :unprocessable_entity
        )
      end

      # Asserts that the requested curve exists and is loadable.
      def ensure_curve_set
        key    = params[:id].to_s.chomp('_curve')
        config = CurveHandler::Config.find(key)
        render_not_found unless scenario.attached_curve(config.db_key)&.loadable_curve?
      end

      # Asserts that the user uploaded a file, and not a string or other object.
      def ensure_upload_is_file
        return if params.require(:file).respond_to?(:tempfile)

        render(
          json: {
            errors: ['"file" was not a valid multipart/form-data file'],
            error_keys: [:not_multipart_form_data]
          },
          status: :unprocessable_entity
        )
      end

      # Asserts that the uploaded file is not too large; there's no reason for 8760 numeric values
      # to exceed one megabyte. Short-circuiting prevents processing large files.
      def ensure_reasonable_file_size
        return unless params.require(:file).size > 1.megabyte

        render(
          json: {
            errors: ['Curve should not be larger than 1MB'],
            error_keys: [:file_too_large]
          },
          status: :unprocessable_entity
        )
      end
    end
  end
end
