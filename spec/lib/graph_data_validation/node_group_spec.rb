require 'spec_helper'
require_relative '../../../lib/graph_data_validation/lib/node_group'

RSpec.describe GraphDataValidation::NodeGroup, :etsource_fixture do
  let(:gql) { Scenario.default.gql }

  context 'with an existing group key' do
    let(:node_group) { described_class.new(:emissions, gql) }

    it 'does not contains molecule nodes' do
      expect(node_group.any? {|n| n.graph_name == :molecules } ).to be_falsey
    end

    it 'contains energy_nodes' do
       expect(node_group.any? {|n| n.graph_name == :energy } ).to be_truthy
    end
  end

  context 'with a non existing group key' do
    let(:node_group) { described_class.new(:no_group, gql) }

     it 'contains no nodes' do
      expect(node_group.first).to be_nil
     end
  end
end
