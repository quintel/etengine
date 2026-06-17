# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ParticipantCapacitiesCSVSerializer do
  # MeritCapacitiesCSVSerializer is used as the concrete vehicle to exercise
  # the module's logic; ReconciliationCapacitiesCSVSerializer would work equally.
  let(:serializer_class) { MeritCapacitiesCSVSerializer }
  let(:graph) { instance_double(Qernel::Graph) }

  let(:producer_api) do
    instance_double(Qernel::NodeApi::Base, input_capacity: 2.0, number_of_units: 10.0)
  end
  let(:producer_node) do
    instance_double(Qernel::Node, key: 'wind_turbine', node_api: producer_api)
  end

  let(:consumer_api) do
    instance_double(Qernel::NodeApi::Base, input_capacity: 1.0, number_of_units: 5.0)
  end
  let(:consumer_node) do
    instance_double(Qernel::Node, key: 'electrolyser', node_api: consumer_api)
  end

  let(:producer_curve) { [100.0, 200.0, 50.0] + ([0.0] * 8757) }
  let(:consumer_curve) { [80.0, 150.0, 30.0] + ([0.0] * 8757) }

  let(:serializer) { serializer_class.new(graph, :electricity, :merit_order) }

  before do
    allow(Qernel::Plugins::Causality).to receive(:enabled?).with(graph).and_return(true)
    allow(producer_api).to receive(:public_send).with('electricity_output_conversion').and_return(0.4)
    allow(consumer_api).to receive(:public_send).with('electricity_input_conversion').and_return(0.9)
    allow(serializer).to receive(:producers).and_return([producer_node])
    allow(serializer).to receive(:consumers).and_return([consumer_node])
    allow(serializer.instance_variable_get(:@adapter))
      .to receive(:node_curve).with(producer_node, :output).and_return(producer_curve)
    allow(serializer.instance_variable_get(:@adapter))
      .to receive(:node_curve).with(consumer_node, :input).and_return(consumer_curve)
  end

  describe '#filename' do
    it 'appends _capacities to the attribute name' do
      expect(serializer.filename).to eq(:merit_order_capacities)
    end
  end

  describe '#to_csv_rows' do
    subject(:rows) { serializer.to_csv_rows }

    it 'includes the header row' do
      expect(rows[0]).to eq(%w[key installed_capacity peak_capacity])
    end

    it 'includes the producer row' do
      # 0.4 * 2.0 * 10.0 = 8.0, peak = 200.0
      expect(rows[1]).to eq(['wind_turbine.output (MW)', 8.0, 200.0])
    end

    it 'includes the consumer row' do
      # 0.9 * 1.0 * 5.0 = 4.5, peak = 150.0
      expect(rows[2]).to eq(['electrolyser.input (MW)', 4.5, 150.0])
    end

    context 'when causality is not enabled' do
      before { allow(Qernel::Plugins::Causality).to receive(:enabled?).with(graph).and_return(false) }

      it 'returns a single error row' do
        expect(rows).to eq([['Merit order and time-resolved calculation are not enabled for this scenario']])
      end
    end

    context 'when a node has zero units' do
      let(:producer_api) do
        instance_double(Qernel::NodeApi::Base, input_capacity: 2.0, number_of_units: 0.0)
      end

      before { allow(producer_api).to receive(:public_send).with('electricity_output_conversion').and_return(0.4) }

      it 'reports 0.0 installed_capacity' do
        expect(rows[1][1]).to eq(0.0)
      end
    end

    context 'when the curve is nil' do
      before do
        allow(serializer.instance_variable_get(:@adapter))
          .to receive(:node_curve).with(producer_node, :output).and_return(nil)
      end

      it 'reports 0.0 peak_capacity' do
        expect(rows[1][2]).to eq(0.0)
      end
    end
  end
end
