module ScenarioPacker
  class Dump
    # Creates a new Scenario API dumper.
    #
    # @param [Scenario] scenario
    #   The scenarios for which we want JSON.
    #
    def initialize(scenario)
      @resource   = scenario
    end

    # Creates a Hash suitable for conversion to JSON by Rails.
    #
    # @return [Hash{Symbol=>Object}]
    #   The Hash containing the scenario attributes.
    #
    def as_json(*)
      json = @resource.as_json(
        only: %i[
          area_code end_year private keep_compatible
          user_values balanced_values active_couplings
          user_curves
        ]
      )
      json[:user_sortables] = @resource.user_sortables.each_with_object({}) do |sortable, hash|
        next unless sortable.persisted?

        if sortable.is_a?(HeatNetworkOrder)
          hash[sortable.class] = [] unless hash.key?(sortable.class)
          hash[sortable.class] << sortable.as_json.merge(temperature: sortable.temperature)
        else
          hash[sortable.class] = sortable.as_json
        end
      end

      json[:user_curves] = @resource.user_curves.each_with_object({}) do |curve, hash|
        hash[curve.key] = curve.curve
      end

      json
    end
  end
end
