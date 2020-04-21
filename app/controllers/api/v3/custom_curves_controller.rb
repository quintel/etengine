module Api
  module V3
    # Provides the ability to upload or remove a custom curve from a scenario.
    #
    # Currently only the imported electricity price curve can be changed, but
    # this controller is intended to allow additional custom curves to be added
    # later without requiring changes to the REST API.
    class CustomCurvesController < BaseController
      # A map of permitted curves to the sanitizer class responsible for
      # checking and formatting the contents of the curve.
      CURVE_SANITIZERS = {
        'imported_electricity_price' => Api::PriceCurveSanitizer
      }.freeze

      # A set containing the list of permitted curve names.
      PERMITTED_CURVES = Set.new(CURVE_SANITIZERS.keys).freeze

      respond_to :json
      before_action :ensure_valid_curve_name, except: :index
      before_action :ensure_reasonable_file_size, only: :update

      # Sends information abuot all custom curves attached to the scenario.
      #
      # GET /api/v3/scenarios/:scenario_id/custom_curves
      def index
        curves =
          CURVE_SANITIZERS.each_key.map do |key|
            attachment_json(attachment(key)).as_json.presence
          end

        render json: curves.compact
      end

      # Sends the name of the current custom curve for the scenario, or an empty
      # object if none is set.
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
        sanitizer = create_sanitizer(params[:id], upload.tempfile)

        if sanitizer.valid?
          current_attachment.attach(
            io: StringIO.new(sanitizer.sanitized_curve.join("\n")),
            filename: upload.original_filename,
            content_type: 'text/csv'
          )

          render json: attachment_json(current_attachment)
        else
          render json: errors_json(sanitizer), status: 422
        end
      end

      # Removes an existing custom curve from a scenario.
      #
      # DELETE /api/v3/scenarios/:scenario_id/custom_curves/:id
      def destroy
        current_attachment.purge if current_attachment.attached?

        render json: {}, status: 200
      end

      private

      def scenario
        Scenario.find(params[:scenario_id])
      end

      def current_attachment
        attachment(params[:id])
      end

      def attachment(type)
        scenario.send("#{type}_curve")
      end

      def attachment_json(attachment)
        CustomCurvePresenter.new(attachment)
      end

      def errors_json(sanitizer)
        { errors: sanitizer.errors, error_keys: sanitizer.error_keys }
      end

      # Internal: Returns the sanitizer class responsible for the given custom
      # curve name.
      def create_sanitizer(curve_name, io)
        content = io.read
        io.rewind

        CURVE_SANITIZERS.fetch(curve_name).from_string(content)
      end

      # Asserts that the named curve is permitted to be changed.
      def ensure_valid_curve_name
        return if PERMITTED_CURVES.include?(params[:id])

        render(
          json: { errors: ["No such custom curve: #{params[:id].inspect}"] },
          status: 422
        )
      end

      # Asserts that the uploaded file is not too large; there's no reason for
      # 8760 numeric values to exceed one megabyte. Short-circuiting prevents
      # processing large files.
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
