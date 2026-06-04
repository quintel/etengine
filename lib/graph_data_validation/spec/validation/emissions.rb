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

