require 'spec_helper'

module Qernel

  describe Node do
    describe 'when no type is specified' do
      it 'uses the default node API' do
        api = FactoryBot.build(:node).node_api
        expect(api).to be_kind_of(Qernel::NodeApi::Base)
      end
    end

    describe 'when the type is :default' do
      it 'uses the default node API' do
        api = FactoryBot.build(:node, groups: [:something]).node_api
        expect(api).to be_kind_of(Qernel::NodeApi::Base)
      end
    end

    describe 'when the type is :demand_driven' do
      it 'uses the demand-driven node API' do
        api = FactoryBot.build(:node, groups: [:something, :demand_driven]).node_api
        expect(api).to be_kind_of(Qernel::NodeApi::DemandDrivenNodeApi)
      end
    end

    describe 'sustainability_share' do
      it 'defaults to 0' do
        node = FactoryBot.build(:node, key: :hi).with({})
        expect(node.query.sustainability_share).to eq(0)
      end

      context 'two nodes connected with a sustainable=0.5 carrier' do
        let(:graph) do
          layout = <<-LAYOUT.strip_heredoc
            useable_heat: left(100) == s(0.25) ==> right
          LAYOUT

          graph = GraphParser.new(layout).build

          allow(graph.node(:left).input_edges.first.carrier)
            .to receive(:sustainable).and_return(0.5)

          graph
        end

        let(:sustainability) { graph.node(:left).query.sustainability_share }

        it 'uses the carrier sustainability' do
          expect(sustainability).to eq(0.5 * 0.25) # sustainability * edge share
        end

        it 'uses the right-most sustainability_share when present' do
          graph.node(:right).dataset_set(:sustainability_share, 0.25)

          expect(sustainability).to eq(0.25 * 0.25)
        end
      end # two nodes connected with a systainable=0.5 carrier

      context 'two nodes connected with a sustainable=0.5 carrier' do
        let(:graph) do
          layout = <<-LAYOUT.strip_heredoc
            useable_heat: left(100) == s(0.25) ==> right
          LAYOUT

          graph = GraphParser.new(layout).build

          allow(graph.node(:left).input_edges.first.carrier)
            .to receive(:sustainable).and_return(nil)

          graph
        end

        let(:sustainability) { graph.node(:left).query.sustainability_share }

        it 'is 0' do
          expect(sustainability).to eq(0)
        end
      end # two nodes connected with a systainable=nil carrier
    end
  end

end
