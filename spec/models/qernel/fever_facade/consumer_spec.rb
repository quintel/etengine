require 'spec_helper'

describe Qernel::FeverFacade::ConsumerAdapter do
  # Creates an adapter double with the given type, subtype, and load curve.
  # def adapter_double(klass_name, type, group, node, curve: nil, adapter_klass: 'Qernel::FeverFacade::Adapter')
  #   adapter = instance_double(adapter_klass)
  #   participant = instance_double(klass_name)

  #   allow(participant).to receive(:load_curve).and_return(curve)

  #   allow(adapter).to receive(:node).and_return(node)
  #   allow(adapter).to receive(:participant).and_return(participant)

  #   # allow(adapter).to receive(:config).and_return(
  #   #   Atlas::NodeAttributes::Fever.new(type: type, group: group)
  #   # )

  #   adapter
  # end

  describe 'share_in_total' do
    let(:consumer) { described_class.new(node, instance_double('Context')) }

    context 'when there are 100 residences and 10 of this type' do
      let(:node) do
        # TODO: look into this: wtf is happening with these nodes and nodeAPi
        # -> will this work? can we do a dataset_get? lets find out
        node_api = instance_double('Qernel::Node')

        allow(node_api).to receive(:key).and_return(:cons)
        allow(node_api).to receive(:demand).and_return(300)
        allow(node_api).to receive(:dataset_get).with(:number_of_cons).and_return(10.0)
        allow(node_api).to receive(:dataset_get).with(:number_of_residences).and_return(100.0)

        node = instance_double('Qernel::Node')
        allow(node).to receive(:node_api).and_return(node_api)
        allow(node).to receive(:dataset_get).with(:fever).and_return(
          Atlas::NodeAttributes::Fever.new(type: :consumer, group: :household_space_heating)
        )

        node
      end

      it 'the share is 0.1' do
        expect(consumer.share_in_total).to eq(0.1)
      end
    end
  end
end
