require 'spec_helper'

module Qernel

  describe Node do
    describe 'when no type is specified' do
      it 'should use the default node API' do
        api = Node.new(id: 1).node_api
        expect(api).to be_kind_of(Qernel::NodeApi)
      end
    end

    describe 'when the type is :default' do
      it 'should use the default node API' do
        api = Node.new(id: 1, groups: [ :something ]).node_api
        expect(api).to be_kind_of(Qernel::NodeApi)
      end
    end

    describe 'when the type is :demand_driven' do
      it 'should use the demand-driven node API' do
        api = Node.new(
          id: 1, groups: [ :something, :demand_driven ]
        ).node_api

        expect(api).to be_kind_of(Qernel::DemandDrivenNodeApi)
      end
    end

    describe 'sustainability_share' do
      it 'defaults to 0' do
        node = Node.new(id: 1, key: :hi).with({})
        expect(node.sustainability_share).to eq(0)
      end

      context 'two nodes connected with a sustainable=0.5 carrier' do
        let(:graph) do
          layout = <<-LAYOUT.strip_heredoc
            useable_heat: left(100) == s(0.25) ==> right
          LAYOUT

          graph = GraphParser.new(layout).build

          allow(graph.node(:left).input_links.first.carrier)
            .to receive(:sustainable).and_return(0.5)

          graph
        end

        let(:sustainability) { graph.node(:left).sustainability_share }

        it 'uses the carrier sustainability' do
          expect(sustainability).to eq(0.5 * 0.25) # sustainability * link share
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

          allow(graph.node(:left).input_links.first.carrier)
            .to receive(:sustainable).and_return(nil)

          graph
        end

        let(:sustainability) { graph.node(:left).sustainability_share }

        it 'is 0' do
          expect(sustainability).to eq(0)
        end
      end # two nodes connected with a systainable=nil carrier
    end
  end

end
