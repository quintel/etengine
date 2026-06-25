# frozen_string_literal: true

module GraphDataValidation
  class EmissionsCsvReconciler
    def initialize(dataset)
      @emissions = Atlas::Dataset.find(dataset.scenario.area_code).emissions
    end

    # Returns the 1990 inventory total in Mt for the given GHG types,
    # excluding bunkers rows and negating LULUCF removals (stored as positive
    # values in the CSV but representing a carbon sink).
    def total_mt(ghgs:)
      @emissions.table.sum do |row|
        next 0.0 unless row[:year] == 1990 && ghgs.include?(row[:ghg])
        next 0.0 if row[:etm_sector].to_s.casecmp?('bunkers')

        value = row[:value].to_f
        removal = row[:etm_sector].to_s.casecmp?('lulucf') &&
          row[:etm_subsector].to_s.casecmp?('removals')
        removal ? -value : value
      end / 1000.0
    end
  end
end
