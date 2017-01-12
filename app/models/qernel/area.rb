module Qernel

  class Area
    include DatasetAttributes

    # Attributes defined in ETSource should not be defined here, but in the
    # Atlas "Dataset" class.
    ATTRIBUTES_USED =
      [Atlas::Dataset::FullDataset, Atlas::Dataset::DerivedDataset].
        map { |klass| klass.attribute_set.map(&:name) }.
        flatten -
        [:id, :parent_id]

    dataset_accessors ATTRIBUTES_USED
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
