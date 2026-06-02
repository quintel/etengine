# For node in emissions group
# test:
#
#
# Fossil test case
# direct_co2_output_content_carriers_fossil <= (direct_co2_input_content_carriers_fossil + direct_co2_input_utilisation_fossil)

#
#
# Biogenic test case
# direct_co2_output_content_carriers_biogenic <= direct_co2_input_content_carriers_biogenic
#
#
# frozen_string_literal: true

RSpec.shared_examples "emissions" do |dataset|
  GraphDataValidation::NodeGroup.new(:emissions, dataset).each do |node|
    context "with node #{node.key}" do
      it 'CO2 going out via output carriers should be either equal or lower than incoming CO2 via input carriers and CO2 utilisation' do
        expect(node.direct_co2_output_content_carriers_fossil).to be <= (
          node.direct_co2_input_content_carriers_fossil +
          node.direct_co2_input_utilisation_fossil
        )
      end

      it 'CO2 going out via output carriers should be either equal or lower than incoming CO2 via input carriers.' do
        # (biogenic does not have CO2 utilisation)
        expect(node.direct_co2_output_content_carriers_biogenic).to be <= (
          node.direct_co2_input_content_carriers_biogenic
        )
      end
    end
  end
end

