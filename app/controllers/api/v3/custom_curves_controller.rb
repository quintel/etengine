# frozen_string_literal: true

module Api
  module V3
    # Provides the ability to upload or remove a custom curve from a scenario.
    #
    # This controller now uses the UserCurve model, which stores curves in the database using
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
        available_curves = Etsource::Config.user_curves
        include_internal = ActiveModel::Type::Boolean.new.cast(params[:include_internal])
        include_unattached = ActiveModel::Type::Boolean.new.cast(params[:include_unattached])

        unless include_internal
          available_curves = available_curves.reject { |_key, config| config.internal? }
        end

        curves = available_curves.values.map do |config|
          if user_curve(config.db_key).blank? && include_unattached
            UnattachedCustomCurveSerializer.new(config).as_json
          else
            curve_json(user_curve(config.db_key))&.as_json
          end
        end

        render json: curves.compact
      end

      # Sends the curve metadata or raw CSV data for a curve stored in the scenario.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves/:name
      def show
        curve = current_user_curve

        if request.format.csv?
          send_data(
            CSV.generate { |csv| curve.as_csv.each { |row| csv << row } },
            type: 'text/csv',
            filename: "#{curve.name.presence || curve.key}.#{curve.scenario_id}.csv"
          )
        else
          render json: curve_json(curve)
        end
      end

      # Creates or updates a custom curve for a scenario.
      #
      # PUT /api/v3/scenarios/:scenario_id/custom_curves/:name
      def update
        upload = params.require(:file)
        handler = create_handler(params[:id], upload)

        if handler.valid?
          render json: curve_json(handler.call)
        else
          render json: errors_json(handler), status: :unprocessable_entity
        end
      end

      # Removes an existing custom curve from a scenario.
      #
      # DELETE /api/v3/scenarios/:scenario_id/custom_curves/:id
      def destroy
        current_user_curve && CurveHandler::DetachService.call(current_user_curve)
        head :no_content
      end

      private

      # Returns the UserCurve record with the given db_key for the scenario.
      def current_user_curve
        user_curve(params[:id])
      end

      # Returns a UserCurve record by the given_key for the scenario.
      def user_curve(key)
        scenario.user_curves.find_by(key: config_for(key).db_key)
      end

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

      # Serialization
      # -------------

      # Returns a serialized representation of the UserCurve.
      def curve_json(curve)
        config_for(curve.key).serializer.new(curve) if curve
      end

      # Returns a standardized JSON format for curve upload validation errors.
      def errors_json(handler)
        { errors: handler.errors, error_keys: handler.error_keys }
      end

      # Factories
      # ---------

      # Finds the curve configuration for the given curve name.
      def config_for(curve_name)
        CurveHandler::Config.find(curve_name.to_s.chomp('_curve'))
      end

      # Returns a CurveHandler::AttachService for handling the curve upload.
      def create_handler(curve_name, io)
        CurveHandler::AttachService.new(
          config_for(curve_name),
          io,
          scenario,
          metadata_parameters
        )
      end

      # Filters
      # -------

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
        render_not_found unless current_user_curve&.loadable_curve?
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
