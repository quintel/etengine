# frozen_string_literal: true

# Provides the requested scenarios in NDJSON line batches as a stream.
module ScenarioPacker
  class StreamNdjson
    SCENARIO_METHODS = %i[start_year inactive_couplings].freeze
    SCENARIO_ATTRIBUTES = %i[
      id area_code end_year source private keep_compatible
      created_at updated_at user_values balanced_values metadata
      active_couplings
    ].freeze

    def initialize(params, ability)
      @scenarios = find_scenarios(ability, Array(params[:ids]))
    end

    # Enumerable-style iteration: yields one hash per scenario.
    def each
      return enum_for(:each) unless block_given?

      @scenarios.each do |scenario|
        yield ndjson_line(scenario)
      end
    end

    private

    def find_scenarios(ability, ids)
      return [] if ids.nil? || ids.empty?

      Scenario.accessible_by(ability).where(id: ids)
    end

    def ndjson_line(scenario)
      json = scenario.as_json(only: SCENARIO_ATTRIBUTES, methods: SCENARIO_METHODS).symbolize_keys
      json[:user_sortables] = sortables(scenario)
      json[:user_curves] = curves(scenario)
      extract_metadata(json)
    end

    def sortables(scenario)
      scenario.user_sortables.each_with_object({}) do |sortable, hash|
        next unless sortable.persisted?

        if sortable.is_a?(HeatNetworkOrder)
          hash[sortable.class] ||= []
          hash[sortable.class] << sortable.as_json.merge(temperature: sortable.temperature)
        else
          hash[sortable.class] = sortable.as_json
        end
      end
    end

    def curves(scenario)
      scenario.user_curves.each_with_object({}) do |curve, hash|
        hash[curve.key] = curve.curve.to_a
      end
    end

    def extract_metadata(json)
       json[:metadata] = {
        id: json[:id],
        source: json[:source],
        created_at: json[:created_at],
        updated_at:json[:updated_at]
      }

      # Remove the moved fields from the main JSON
      json.except(:id, :source, :created_at, :updated_at)
    end
  end
end