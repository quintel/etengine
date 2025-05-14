# frozen_string_literal: true

module Curves
  class Manager

    class Result < Struct.new(:series, :filename, :json, :errors, :error_keys)
      def csv_data
        CSV.generate do |csv|
          series.each { |value| csv << [value] }
        end
      end
    end

    def initialize(scenario, params, metadata = {})
      @scenario = scenario
      @params   = params
      @metadata = metadata
    end

    def index
      available = Etsource::Config.user_curves.values
      available = available.reject(&:internal?) unless bool(:include_internal)

      curves = available.map do |curve_config|
        if attached_keys.include?(curve_config.db_key)
          curve_config.serializer.new(user_curve(curve_config.db_key)).as_json
        elsif bool(:include_unattached)
          UnattachedCustomCurveSerializer.new(curve_config).as_json
        end
      end.compact

      Result.new(curves)
    end

    def show
      curve_config = find_config!
      user_curve   = find_curve!(curve_config)
      raw_curve    = user_curve.curve
      series       = process(raw_curve, user_curve, curve_config)
      json         = curve_config.serializer.new(user_curve).as_json
      filename     = "#{user_curve.name || user_curve.key}.csv"

      Result.new(series, filename, json)
    end

    def update
      curve_config = find_config!
      upload       = @params.require(:file)
      handler      = CurveHandler::AttachService.new(curve_config, upload, @scenario, @metadata)

      if handler.valid?
        user_curve = handler.call
        json       = curve_config.serializer.new(user_curve).as_json
        Result.new(nil, nil, json)
      else
        Result.new(nil, nil, nil, handler.errors, handler.error_keys)
      end
    end

    def destroy
      curve_config = find_config!
      if (user_curve = @scenario.attached_curve(curve_config.db_key))
        CurveHandler::DetachService.call(user_curve)
      end
      Result.new
    end

    private

    def attached_keys
      @attached_keys ||= @scenario.attached_curve_keys
    end

    def user_curve(db_key)
      @scenario.attached_curve(db_key)
    end

    def bool(key)
      ActiveModel::Type::Boolean.new.cast(@params[key])
    end

    def find_config!
      CurveHandler::Config.find(@params[:id].to_s.chomp('_curve'))
    end

    def find_curve!(curve_config)
      user_curve = @scenario.attached_curve(curve_config.db_key)
      raise ActiveRecord::RecordNotFound unless user_curve&.loadable_curve?
      user_curve
    end

    def process(raw_curve, user_curve, curve_config)
      return raw_curve unless curve_config.processor_key == :capacity_profile

      full_load_hours = user_curve.scenario.user_values.fetch(curve_config.input_keys.first)
      CurveHandler::Reducers::Rescaler.new(raw_curve, full_load_hours).call
    end
  end
end
