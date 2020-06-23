# frozen_string_literal: true

require 'spec_helper'

describe Qernel::Slot::EdgeBased do
  let(:graph) do
    layout = <<-LAYOUT.strip_heredoc
      electricity[1.0;0.9(edge_based)]: elec_output  == s(1.0)  ==> network
      loss[1.0;0.1]:                    loss_output  == s(1.0)  ==> network
    LAYOUT

    Qernel::GraphParser.new(layout).build
  end

  let(:network)     { graph.node(:network) }
  let(:loss)        { network.output(:loss) }
  let(:electricity) { network.output(:electricity) }

  let(:loss_edge)   { loss.edges.first }
  let(:elec_edge)   { electricity.edges.first }

  before do
    # GraphParser adds a conversion; get rid of it.
    electricity.dataset_attributes.delete(:conversion)
  end

  # --------------------------------------------------------------------------

  context 'when a value is known for all edges' do
    before do
      loss_edge.value = 25.0
      elec_edge.value = 75.0
    end

    it 'calculates the EdgeBased conversion' do
      expect(electricity.conversion).to eq(0.75)
    end

    it 'does not affect sibling slots' do
      expect(loss.conversion).to eq(0.1)
    end

    it 'does not recalculate when data changes' do
      expect { elec_edge.value = 25.0 }
        .not_to change(electricity, :conversion).from(0.75)
    end
  end

  context 'when all the edges are zero' do
    before do
      loss_edge.value = 0.0
      elec_edge.value = 0.0
    end

    it 'calculates the EdgeBased conversion as zero' do
      expect(electricity.conversion).to eq(0.0)
    end
  end

  context 'when a :edge_based_conversion value is stored' do
    before do
      loss_edge.value = 25.0
      elec_edge.value = 75.0

      electricity.dataset_set(:edge_based_conversion, 1.0)
    end

    it 'retrieves the cached value' do
      expect(electricity.conversion).to eq(1.0)
    end
  end

  context 'when the edge has no value' do
    before do
      loss_edge.value = 25.0
      elec_edge.value = nil
    end

    it 'does not calculate a value; returning zero' do
      expect(electricity.conversion).to eq(0)
    end

    it 'does not cache the returned value as :conversion' do
      expect(electricity.dataset_get(:conversion)).to be_nil
    end

    it 'does not cache the returned value as :edge_based_conversion' do
      expect(electricity.dataset_get(:edge_based_conversion)).to be_nil
    end

    it 'calculates once enough data is available' do
      expect { elec_edge.value = 25.0 }
        .to change(electricity, :conversion)
        .from(0.0).to(0.5)
    end

    context 'when a :conversion is cached' do
      before { electricity.dataset_set(:conversion, 0.4) }

      it 'returns the cached :conversion' do
        expect(electricity.conversion).to eq(0.4)
      end
    end
  end

  context 'when a sibling slot edge has no value' do
    before do
      loss_edge.value = nil
      elec_edge.value = 75.0
    end

    it 'does not calculate a value; returning zero' do
      expect(electricity.conversion).to eq(0)
    end
  end
end
