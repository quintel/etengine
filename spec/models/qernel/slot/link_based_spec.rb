# frozen_string_literal: true

require 'spec_helper'

describe Qernel::Slot::LinkBased do
  let(:graph) do
    layout = <<-LAYOUT.strip_heredoc
      electricity[1.0;0.9(link_based)]: elec_output  == s(1.0)  ==> network
      loss[1.0;0.1]:                    loss_output  == s(1.0)  ==> network
    LAYOUT

    Qernel::GraphParser.new(layout).build
  end

  let(:network)     { graph.node(:network) }
  let(:loss)        { network.output(:loss) }
  let(:electricity) { network.output(:electricity) }

  let(:loss_link)   { loss.links.first }
  let(:elec_link)   { electricity.links.first }

  before do
    # GraphParser adds a conversion; get rid of it.
    electricity.dataset_attributes.delete(:conversion)
  end

  # --------------------------------------------------------------------------

  context 'when a value is known for all links' do
    before do
      loss_link.value = 25.0
      elec_link.value = 75.0
    end

    it 'calculates the LinkBased conversion' do
      expect(electricity.conversion).to eq(0.75)
    end

    it 'does not affect sibling slots' do
      expect(loss.conversion).to eq(0.1)
    end

    it 'does not recalculate when data changes' do
      expect { elec_link.value = 25.0 }
        .not_to change(electricity, :conversion).from(0.75)
    end
  end

  context 'when all the links are zero' do
    before do
      loss_link.value = 0.0
      elec_link.value = 0.0
    end

    it 'calculates the LinkBased conversion as zero' do
      expect(electricity.conversion).to eq(0.0)
    end
  end

  context 'when a :link_based_conversion value is stored' do
    before do
      loss_link.value = 25.0
      elec_link.value = 75.0

      electricity.dataset_set(:link_based_conversion, 1.0)
    end

    it 'retrieves the cached value' do
      expect(electricity.conversion).to eq(1.0)
    end
  end

  context 'when the link has no value' do
    before do
      loss_link.value = 25.0
      elec_link.value = nil
    end

    it 'does not calculate a value; returning zero' do
      expect(electricity.conversion).to eq(0)
    end

    it 'does not cache the returned value as :conversion' do
      expect(electricity.dataset_get(:conversion)).to be_nil
    end

    it 'does not cache the returned value as :link_based_conversion' do
      expect(electricity.dataset_get(:link_based_conversion)).to be_nil
    end

    it 'calculates once enough data is available' do
      expect { elec_link.value = 25.0 }
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

  context 'when a sibling slot link has no value' do
    before do
      loss_link.value = nil
      elec_link.value = 75.0
    end

    it 'does not calculate a value; returning zero' do
      expect(electricity.conversion).to eq(0)
    end
  end
end
