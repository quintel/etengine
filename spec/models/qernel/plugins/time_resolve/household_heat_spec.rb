require 'spec_helper'

RSpec.describe Qernel::Plugins::TimeResolve::HouseholdHeat, :household_curves do
  let(:old_household_insulation_level) { 0.25 }
  let(:new_household_insulation_level) { 0.75 }

  let(:heat) do
    Qernel::Plugins::TimeResolve::HouseholdHeat.new(
      stub_space_heating(
        create_graph,
        old_share: old_household_share,
        old_level: old_household_insulation_level,
        new_level: new_household_insulation_level
      ),
      create_curve_set
    )
  end

  describe 'with 75% old households, 25% new' do
    let(:old_household_share) { 0.75 }

    context 'with insulation "shares" of 0.25/0.75' do
      it 'creates a combined profile' do
        values = heat.demand_curve(8760.0).take(4)

        # old households share of uninsulated = 0.5625
        #                      of insulated   = 0.1875

        # new households share of uninsulated = 0.0625
        #                      of insulated   = 0.1875

        # uninsulated = 0.0, 2.0, 0.0, 2.0
        # insulated   = 2.0, 0.0, 2.0, 0.0

        expect(values).to eq([
          0.375 * 2.0,
          0.625 * 2.0,
          0.375 * 2.0,
          0.625 * 2.0
        ])
      end

      it 'has an area equal to demand' do
        expect(heat.demand_curve(8760).sum).to eq(8760)
      end
    end

    context 'with insulation "shares" of 0.25/0.25' do
      let(:old_household_insulation_level) { 0.25 }
      let(:new_household_insulation_level) { 0.25 }

      it 'creates a combined profile' do
        values = heat.demand_curve(8760.0).take(4)

        # old households share of uninsulated = 0.5625
        #                      of insulated   = 0.1875

        # new households share of uninsulated = 0.1875
        #                      of insulated   = 0.0625

        # uninsulated = 0.0, 2.0, 0.0, 2.0
        # insulated   = 2.0, 0.0, 2.0, 0.0

        expect(values).to eq([
          0.25 * 2.0,
          0.75 * 2.0,
          0.25 * 2.0,
          0.75 * 2.0
        ])
      end

      it 'has an area equal to demand' do
        expect(heat.demand_curve(8760).sum).to eq(8760)
      end
    end
  end

  describe 'with 25% old houseolds, 75% new' do
    let(:old_household_share) { 0.25 }

    context 'with a "share" of 0.75 (25/75 profile mix)' do
      it 'creates a combined profile' do
        values = heat.demand_curve(8760).take(4)

        # old households share of uninsulated = 0.0625
        #                      of insulated   = 0.1875

        # new households share of uninsulated = 0.5625
        #                      of insulated   = 0.1875

        # uninsulated = 0.0, 2.0, 0.0, 2.0
        # insulated   = 2.0, 0.0, 2.0, 0.0

        expect(values).to eq([
          0.625 * 2.0,
          0.375 * 2.0,
          0.625 * 2.0,
          0.375 * 2.0
        ])
      end

      it 'has an area equal to demand' do
        expect(heat.demand_curve(8760).sum).to eql(8760.0)
      end
    end
  end
end
