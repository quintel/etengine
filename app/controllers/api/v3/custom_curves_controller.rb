module Api
  module V3
    # Provides the ability to upload or remove a custom curve from a scenario.
    #
    # Currently only the imported electricity price curve can be changed, but this controller is
    # intended to allow additional custom curves to be added later without requiring changes to the
    # REST API.
    class CustomCurvesController < BaseController
      include UsesScenario

      respond_to :json

      before_action :ensure_valid_curve_name, except: :index
      before_action :ensure_upload_is_file, only: :update
      before_action :ensure_reasonable_file_size, only: :update
      before_action :ensure_curve_set, only: %i[show destroy]

      # Sends information about all custom curves attached to the scenario.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves
      def index
        available_curves = Etsource::Config.user_curves

        unless params[:include_internal]
          available_curves = available_curves.reject { |_key, config| config.internal? }
        end

        curves = available_curves.values.map do |config|
          if attachment(config.key).blank? && params[:include_unattached]
            UnattachedCustomCurveSerializer.new(config).as_json
          else
            attachment_json(attachment(config.key)).as_json.presence
          end
        end

        render json: curves.compact
      end

      # Sends the name of the current custom curve for the scenario, or an empty object if none is
      # set.
      #
      # If the request wants CSV, the file contents will be sent.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves/:name
      def show
        attachment = current_attachment

        respond_to do |format|
          format.csv do
            send_data(
              attachment.file.blob.download,
              type: 'text/csv',
              filename: "#{attachment.key}.#{attachment.scenario_id}.csv"
            )
          end

          format.any do
            render json: attachment_json(attachment)
          end
        end
      end

      # Creates or updates a custom curve for a scenario.
      #
      # PUT /api/v3/scenarios/:scenario_id/custom_curves/:name
      def update
        upload = params.require(:file)
        handler = create_handler(params[:id], upload)

        if handler.valid?
          render json: attachment_json(handler.call)
        else
          render json: errors_json(handler), status: :unprocessable_entity
        end
      end

      # Removes an existing custom curve from a scenario.
      #
      # DELETE /api/v3/scenarios/:scenario_id/custom_curves/:id
      def destroy
        current_attachment && CurveHandler::DetachService.call(current_attachment)
        head :no_content
      end

      private

      def scenario_attachments
        ScenarioAttachment.where(scenario_id: params[:scenario_id])
      end

      def current_attachment
        attachment(params[:id])
      end

      def attachment(key)
        return if scenario_attachments.empty?

        scenario_attachments.find_by(key: config_for(key).db_key)
      end

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

      def attachment_json(attachment)
        config_for(attachment.key).serializer.new(attachment) if attachment
      end

      def errors_json(handler)
        { errors: handler.errors, error_keys: handler.error_keys }
      end

      # Factories
      # ---------

      def config_for(curve_name)
        CurveHandler::Config.find(curve_name.to_s.chomp('_curve'))
      end

      # Internal: Returns the handler based on the curve name, initialized with the IO.
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

      # Asserts that the named curve is permitted to be changed.
      def ensure_valid_curve_name
        return if CurveHandler::Config.key?(params[:id])

        render(
          json: { errors: ["No such custom curve: #{params[:id].inspect}"] },
          status: 422
        )
      end

      def ensure_curve_set
        render_not_found unless current_attachment&.file&.attached?
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

      # Asserts that the uploaded file is not too large; there's no reason for 8760 numeric values
      # to exceed one megabyte. Short-circuiting prevents processing large files.
      def ensure_reasonable_file_size
        return unless params.require(:file).size > 1.megabyte

        render(
          json: {
            errors: ['Curve should not be larger than 1MB'],
            error_keys: [:file_too_large]
          },
          status: 422
        )
      end
    end
  end
end
