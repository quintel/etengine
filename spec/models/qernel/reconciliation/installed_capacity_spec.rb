# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Installed capacity of Reconciliation participants' do
  let(:slot) { double('Slot', conversion: 0.5) }
  let(:node) { double('Node', node_api: double('NodeApi', input_capacity: 2.0, number_of_units: 10.0)) }
  let(:context) { double('Context', carrier: :network_gas) }
  let(:config) { double('Config', demand_carrier: :natural_gas) }

  def build_adapter(klass)
    klass.allocate.tap do |adapter|
      adapter.instance_variable_set(:@node, node)
      adapter.instance_variable_set(:@config, config)
      adapter.instance_variable_set(:@context, context)
    end
  end

  context 'with a consumer' do
    before do
      allow(node).to receive(:input).with(:natural_gas).and_return(slot)
    end

    it 'sets the input capacity of its demand carrier' do
      expect(node).to receive(:dataset_set).with(:network_gas_input_installed_capacity, 10.0)
      expect(node).to receive(:dataset_set).with(:network_gas_output_installed_capacity, nil)

      build_adapter(Qernel::Reconciliation::ConsumerAdapter).inject_installed_capacity!
    end
  end

  it 'gives a producer the output capacity of its demand carrier' do
    allow(node).to receive(:output).with(:natural_gas).and_return(slot)
    expect(build_adapter(Qernel::Reconciliation::ProducerAdapter).send(:installed_output_capacity))
      .to eq(10.0)
  end

  it 'gives storage, which follows the balance, no capacity' do
    expect(build_adapter(Qernel::Reconciliation::StorageAdapter).send(:installed_output_capacity))
      .to be_nil
  end
end
