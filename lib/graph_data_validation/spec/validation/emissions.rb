# frozen_string_literal: true

RSpec.shared_examples "emissions" do |dataset|
  GraphDataValidation::NodeGroup.new(:emissions, dataset).each do |node|
    context "emissions for node #{node.key}" do
      it 'should balance for fossil' do
        expect((
          node.direct_co2_input_content_carriers_fossil +
          node.direct_co2_input_utilisation_fossil
        )).to match_output(node.direct_co2_output_content_carriers_fossil)
      end

      it 'should balance for biogenic' do
        # (biogenic does not have CO2 utilisation)
        expect(node.direct_co2_input_content_carriers_biogenic).to match_output(
          node.direct_co2_output_content_carriers_biogenic
        )
      end
    end
  end

  # Reconcile the 1990 direct_emissions total queries against the dataset's
  # emissions.csv (read from the local ETSource).
  #
  # Bunkers is excluded on both sides: its query scales the inventory by the
  # bunkers_allocated_percentage_* inputs (default 0), so it cannot equal the raw
  # CSV. Subtracting the bunkers query and the Bunkers CSV rows makes the check
  # allocation-independent.
  #
  # LULUCF removals are stored as positive values in the CSV but represent a
  # carbon sink; the queries subtract them (NEG), so the CSV sum negates them too.
  emissions = Atlas::Dataset.find(dataset.scenario.area_code).emissions

  [
    { total: 'direct_emissions_co2_1990',       bunkers: 'direct_emissions_bunkers_co2_1990',       ghgs: %w[co2] },
    { total: 'direct_emissions_other_ghg_1990', bunkers: 'direct_emissions_bunkers_other_ghg_1990', ghgs: %w[other_ghg] },
    { total: 'direct_emissions_total_ghg_1990', bunkers: 'direct_emissions_bunkers_total_ghg_1990', ghgs: %w[co2 other_ghg] }
  ].each do |check|
    # Queries report Mt; the inventory CSV is in kton CO2-eq. Exclude bunkers.
    queried_mt = dataset.query("present:Q(#{check[:total]})") -
                 dataset.query("present:Q(#{check[:bunkers]})")
    emissions_csv_mt = emissions.table.sum do |row|
      next 0.0 unless row[:year] == 1990 && check[:ghgs].include?(row[:ghg])
      next 0.0 if row[:etm_sector].to_s.casecmp?('bunkers')

      value = row[:value].to_f
      removal = row[:etm_sector].to_s.casecmp?('lulucf') &&
                row[:etm_subsector].to_s.casecmp?('removals')
      removal ? -value : value
    end / 1000.0

    context "1990 inventory reconciliation for #{check[:total]}" do
      it 'matches emissions.csv (excl. bunkers)' do
        expect(queried_mt).to be_within(0.001 * emissions_csv_mt + 1e-6).of(emissions_csv_mt)
      end
    end
  end
end
