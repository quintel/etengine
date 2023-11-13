# frozen_string_literal: true

require 'spec_helper'

describe Etsource::Fever do
  describe 'group' do
    let(:group) { described_class.group(name) }

    context 'with a valid group' do
      let(:name) { :buildings_space_heating }

      it 'returns the producers in the right order' do
        expect(group.keys(:producer)).to eq(
          %i[buildings_space_heater_heatpump buildings_space_heater_coal buildings_space_heater_gas]
        )
      end
    end
  end
end
