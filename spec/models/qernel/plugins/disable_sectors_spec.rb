require 'spec_helper'

module Qernel::Plugins
  describe DisableSectors do
    let(:gql) do
      gql = Scenario.default(
        user_values: { settings_enable_merit_order: 0 }
      ).gql(prepare: false)

      gql.init_datasets
      gql.update_graphs
      gql
    end

    context 'when there is one disabled sector' do
      before do
        gql.future.graph.area.disabled_sectors = [:nosector]
        gql.calculate_graphs
      end

      it 'is run' do
        expect(gql.future.graph.plugin(:disable_sectors)).to be
      end

      it 'zeroes out disabled sectors' do
        expect(gql.future.graph.node(:foo).demand).to be_zero
      end

      it 'does not zero-out enabled sectors' do
        expect(gql.future.graph.node(:cpd_sink).demand).to_not be_zero
      end
    end # when there is one disabled sector

    context 'when there are no disabled sectors' do
      before do
        gql.calculate_graphs
      end

      it 'is not run' do
        expect(gql.future.graph.plugin(:disable_sectors)).to_not be
      end

      it 'zeroes out no sectors' do
        expect(gql.future.graph.node(:foo).demand).to_not be_zero
      end
    end # when there are no disabled sectors
  end
end # Qernel::Plugins
