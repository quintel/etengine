require 'spec_helper'

describe 'Qernel::Slot::CarrierEfficient' do
  let(:graph) do
    layout = <<-LAYOUT.strip_heredoc
      electricity[0.5]:                        network(100) == s(0.50) ==> supply_one
      cooling[0.5]:                            network      == s(0.50) ==> supply_two
      electricity[1.0;1.0(carrier_efficient)]: output       == s(1.0)  ==> network
    LAYOUT

    Qernel::GraphParser.new(layout).build
  end # graph

  let(:network)    { graph.converters.detect { |c| c.key == :network    } }
  let(:supply_one) { graph.converters.detect { |c| c.key == :supply_one } }
  let(:supply_two) { graph.converters.detect { |c| c.key == :supply_two } }

  let(:slot)       { network.output(:electricity) }

  before do
    network.with(carrier_efficiency: { electricity: {
      electricity: 0.4, cooling: 0.6 }})

    # GraphParser adds a conversion; get rid of it.
    slot.dataset_attributes.delete(:conversion)
  end

  it 'changes when the proportion of inputs change' do
    network.input(:electricity).dataset_set(:conversion, 0.2)
    network.input(:cooling).dataset_set(:conversion, 0.8)

    expect(slot.conversion).to eql(0.56)
  end

  it 'permits one slot to provide 100% of demand' do
    network.input(:electricity).dataset_set(:conversion, 1.0)
    network.input(:cooling).dataset_set(:conversion, 0.0)

    expect(slot.conversion).to eql(0.4)
  end

  it 'raises if no efficiency data is present' do
    network.dataset_attributes.delete(:carrier_efficiency)

    pending 'Pending stopping rescuing all graph exceptions' do
      expect(slot.method(:conversion)).to raise_error(
        Qernel::Slot::CarrierEfficient::InsufficientCarrierData,
        /but the :carrier_efficiency attribute is blank/)
    end
  end

  it 'raises if no efficiency data for the output carrier is present' do
    network.with(carrier_efficiency: { useable_heat: { electricity: 0.4 } })

    pending 'Pending stopping rescuing all graph exceptions' do
      expect(slot.method(:conversion)).to raise_error(
        Qernel::Slot::CarrierEfficient::InsufficientCarrierData,
        /but only has carrier efficiency data for \[\]/)
    end
  end

  it 'raises if insufficient efficiency data is present' do
    network.with(carrier_efficiency: { electricity: { electricity: 0.4 } })

    pending 'Pending stopping rescuing all graph exceptions' do
      expect(slot.method(:conversion)).to raise_error(
        Qernel::Slot::CarrierEfficient::InsufficientCarrierData,
        /but only has carrier efficiency data for \[:electricity\]/)
    end
  end
end # Qernel::Slot::CarrierEfficient
