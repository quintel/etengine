# frozen_string_literal: true

module Qernel
  class Area
    include DatasetAttributes

    # Attributes defined in ETSource should not be defined here, but in the
    # Atlas "Dataset" class.
    ATTRIBUTES_USED =
      [Atlas::Dataset::Full, Atlas::Dataset::Derived].
        map { |klass| klass.attribute_set.map(&:name) }.
        flatten -
        [:id, :parent_id]

    dataset_accessors ATTRIBUTES_USED
    dataset_accessors :insulation_level_new_houses
    dataset_accessors :insulation_level_old_houses
    dataset_accessors :weather_curve_set
    dataset_accessors :disabled_sectors

    attr_accessor :graph
    attr_reader :dataset_key, :key

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?
      @dataset_key = @key = :area_data
    end

    # Remove when we replace :area with :area_code
    def area_code
      area
    end

    def inspect
      "<Area #{area_code}>"
    end

    def disabled_sectors
      dataset_get(:disabled_sectors) || []
    end

    def insulation_costs(file)
      Etsource::Dataset.insulation_costs(area_code, file)
    end

    def insulation_level_old_houses
      fetch(:insulation_level_old_houses) { insulation_level_old_houses_min }
    end

    def insulation_level_new_houses
      fetch(:insulation_level_new_houses) { insulation_level_new_houses_min }
    end

    def weather_curve_set
      fetch(:weather_curve_set) { 'default' }
    end

    def weather_properties
      Etsource::Dataset.weather_properties(area_code, weather_curve_set)
    end

    # ----- attributes/methods still used in gqueries. should be properly added to etsource or change gqueries.

    def co2_emission_1990_billions
      co2_emission_1990 * BILLIONS
    end

    # ?!
    def manure_available_in_pj=(param)
      param
    end

    # ?!
    def manure_available_in_pj
      0.0
    end
  end
end
