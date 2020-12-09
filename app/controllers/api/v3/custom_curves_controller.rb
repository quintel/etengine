module Api
  module V3
    # Provides the ability to upload or remove a custom curve from a scenario.
    #
    # Currently only the imported electricity price curve can be changed, but this controller is
    # intended to allow additional custom curves to be added later without requiring changes to the
    # REST API.
    class CustomCurvesController < BaseController
      # A map of permitted curves to the handler class responsible for checking and formatting the
      # contents of the curve.
      CURVE_HANDLERS = {
        'interconnector_1_price' => CurveHandler::Price,
        'interconnector_2_price' => CurveHandler::Price,
        'interconnector_3_price' => CurveHandler::Price,
        'interconnector_4_price' => CurveHandler::Price,
        'interconnector_5_price' => CurveHandler::Price,
        'interconnector_6_price' => CurveHandler::Price
      }.freeze

      # A set containing the list of permitted curve names.
      PERMITTED_CURVES = Set.new(CURVE_HANDLERS.keys).freeze

      respond_to :json

      before_action :ensure_valid_curve_name, except: :index
      before_action :ensure_upload_is_file, only: :update
      before_action :ensure_reasonable_file_size, only: :update
      before_action :ensure_curve_set, only: %i[show destroy]

      # Sends information about all custom curves attached to the scenario.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves
      def index
        curves =
          CURVE_HANDLERS.each_key.map do |key|
            attachment_json(attachment(key)).as_json.presence
          end

        render json: curves.compact
      end

      # Sends the name of the current custom curve for the scenario, or an empty object if none is
      # set.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves/:name
      def show
        render json: attachment_json(current_attachment)
      end

      # Creates or updates a custom curve for a scenario.
      #
      # PUT /api/v3/scenarios/:scenario_id/custom_curves/:name
      def update
        upload = params.require(:file)
        handler = create_handler(params[:id], upload.tempfile)

        if handler.valid?
          update_or_create_attachment(params[:id], metadata_parameters)

          current_attachment.file.attach(
            io: StringIO.new(handler.sanitized_curve.join("\n")),
            filename: upload.original_filename,
            content_type: 'text/csv'
          )

          render json: attachment_json(current_attachment)
        else
          render json: errors_json(handler), status: 422
        end
      end

      # Removes an existing custom curve from a scenario.
      #
      # DELETE /api/v3/scenarios/:scenario_id/custom_curves/:id
      def destroy
        current_attachment&.destroy
        head :no_content
      end

      private

      def scenario_attachments
        ScenarioAttachment.where(scenario_id: params[:scenario_id])
      end

      def current_attachment
        attachment(params[:id])
      end

      def attachment(type)
        return if scenario_attachments.empty?

        scenario_attachments.find_by(key: "#{type}_curve")
      end

      def update_or_create_attachment(type, metadata)
        unless current_attachment
          ScenarioAttachment.create(
            key: "#{type}_curve",
            scenario_id: params[:scenario_id]
          )
        end

        # If new metadata is not supplied, remove old metadata
        current_attachment.update_or_remove_metadata(metadata)
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

      def attachment_json(attachment)
        attachment ? handler_class_for(attachment.key).presenter.new(attachment) : {}
      end

      def errors_json(handler)
        { errors: handler.errors, error_keys: handler.error_keys }
      end

      # Internal: Fetches the handler class responsible for the given custom curve name.
      def handler_class_for(curve_name)
        CURVE_HANDLERS.fetch(curve_name.to_s.chomp('_curve'))
      end

      # Internal: Returns the handler based on the curve name, initialized with the IO.
      def create_handler(curve_name, io)
        content = io.read
        io.rewind

        handler_class_for(curve_name).from_string(content)
      end

      # Asserts that the named curve is permitted to be changed.
      def ensure_valid_curve_name
        return if PERMITTED_CURVES.include?(params[:id])

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
