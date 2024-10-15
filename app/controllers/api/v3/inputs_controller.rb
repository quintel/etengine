# frozen_string_literal: true
require 'csv'

module Api
  module V3
    class InputsController < ::Api::V3::BaseController
      before_action do
        @scenario = Scenario.find(params[:scenario_id])
        if user_signed_in? && current_user.can?(:read, @scenario)
          authorize!(:read, @scenario)
        end
      end

      # GET /api/v3/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs.csv
      #
      # Returns input details in JSON or CSV format. Uses the latest scenario if
      # scenario_id is not provided.

      def index
        extras = ActiveModel::Type::Boolean.new.cast(params[:include_extras])
        inputs = serialized_inputs(extras)

        respond_to do |format|
          format.json { render json: inputs }
          format.csv { send_csv_data(inputs) }
        end
      end

      # GET /api/v3/inputs/:id
      # GET /api/v3/scenarios/:scenario_id/inputs/:id
      # GET /api/v3/scenarios/:scenario_id/inputs/:id_1,:id_2,...,:id_N
      #
      # Returns the input details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code.  The inputs
      # are stored in the db and in the etsource, too. At the moment this
      # action uses the DB records. To be updated.
      #
      def show
        record =
          if params.key?(:id) && params[:id].include?(',')
            params[:id].split(',').compact.uniq.map do |id|
              InputSerializer.serializer_for(
                fetch_input(id),
                @scenario,
                **serializer_args(extra_attributes: true)
              )
            end
          else
            InputSerializer.serializer_for(
              fetch_input(params[:id]), @scenario, **serializer_args(extra_attributes: true)
            )
          end

        render json: record
      rescue ActiveRecord::RecordNotFound => e
        render_not_found(errors: [e.message])
      end

      # GET /api/v3/inputs/list.json
      #
      # Returns a JSON-encoded array of inputs. Used to transition from v2 to
      # v3 and replace ids with keys. Can be deleted when all applications
      # will have been upgraded.
      #
      def list
        render json: Input.all.map{|i| {id: i.id, key: i.key}}
      end

      private

      def fetch_input(id)
        (input = Input.get(id)) ? input : raise(ActiveRecord::RecordNotFound)
      end

      def serializer_args(extra_attributes:)
        {
          can_change: current_ability.can?(:update, @scenario),
          default_values_from: params[:defaults] ? params[:defaults].to_sym : :parent,
          extra_attributes:
        }
      end

      def serialized_inputs(extras)
        InputSerializer.collection(
          Input.all,
          @scenario,
          **serializer_args(extra_attributes: extras)
        )
      end

      def send_csv_data(inputs)
        csv_data = generate_csv(inputs)
        send_data csv_data, filename: "inputs_#{@scenario.id}.csv"
      end

      def generate_csv(inputs)
        CSV.generate(headers: true) do |csv|
          csv << csv_headers
          cached_values = Input.cache(@scenario.parent)
          user_values = @scenario.user_values

          inputs.each do |key, input|
            add_csv_row(csv, key, input, cached_values, user_values)
          end
        end
      end

      def csv_headers
        ["Key", "Min", "Max", "Default", "User Value", "Unit", "Share Group"]
      end

      def add_csv_row(csv, key, input, cached_values, user_values)
        input_data = input.instance_variable_get(:@input)
        return if input_data.nil?

        values = cached_values.read(@scenario.parent, input_data)
        default_value = input.instance_variable_get(:@default_values_from).call(values)

        csv << [
          key,
          input_data.min_value,
          input_data.max_value,
          default_value,
          user_values[input_data.key] || "",
          input_data.unit,
          input_data.share_group
        ]
      end
    end
  end
end
