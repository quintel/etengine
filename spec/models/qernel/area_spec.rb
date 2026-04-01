require 'spec_helper'

module Qernel
  describe Area do
    describe 'emissions' do
      let(:graph) { Qernel::Graph.new }
      let(:area) { graph.area }

      it 'initializes with an emissions object' do
        expect(area.emissions).to be_a(Qernel::Emissions)
      end

      it 'passes the graph reference to emissions' do
        expect(area.emissions.graph).to eq(graph)
      end

      it 'maintains the same emissions instance' do
        first_call = area.emissions
        second_call = area.emissions
        expect(first_call.object_id).to eq(second_call.object_id)
      end

      it 'allows setting emission values' do
        area.emissions.with({})
        area.emissions.dataset_set(:households_co2, 100.0)
        expect(area.emissions.dataset_get(:households_co2)).to eq(100.0)
      end

      it 'provides scoped access to emissions' do
        area.emissions.with({})
        attrs = area.emissions.instance_variable_get(:@dataset_attributes)
        attrs['industry_other_ghg'] = 50.0
        expect(area.emissions.scope(:industry)[:other_ghg]).to eq(50.0)
      end
    end
  end
end
