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
end

RSpec.shared_examples('emissions_1990_reconciliation') do |dataset|
  reconciler = GraphDataValidation::EmissionsCsvReconciler.new(dataset)

  context 'with 1990 CO2 emissions' do
    queried_mt =
      dataset.query('present:Q(direct_emissions_co2_1990)') -
      dataset.query('present:Q(direct_emissions_bunkers_co2_1990)')
    expected_mt = reconciler.total_mt(ghgs: %w[co2])

    it 'matches emissions.csv (excluding bunkers)' do
      expect(queried_mt).to be_within((0.001 * expected_mt) + 1e-6).of(expected_mt)
    end
  end

  context 'with 1990 other greenhouse gas emissions' do
    queried_mt =
      dataset.query('present:Q(direct_emissions_other_ghg_1990)') -
      dataset.query('present:Q(direct_emissions_bunkers_other_ghg_1990)')
    expected_mt = reconciler.total_mt(ghgs: %w[other_ghg])

    it 'matches emissions.csv (excluding bunkers)' do
      expect(queried_mt).to be_within((0.001 * expected_mt) + 1e-6).of(expected_mt)
    end
  end

  context 'with 1990 total greenhouse gas emissions' do
    queried_mt =
      dataset.query('present:Q(direct_emissions_total_ghg_1990)') -
      dataset.query('present:Q(direct_emissions_bunkers_total_ghg_1990)')
    expected_mt = reconciler.total_mt(ghgs: %w[co2 other_ghg])

    it 'matches emissions.csv (excluding bunkers)' do
      expect(queried_mt).to be_within((0.001 * expected_mt) + 1e-6).of(expected_mt)
    end
  end
end
