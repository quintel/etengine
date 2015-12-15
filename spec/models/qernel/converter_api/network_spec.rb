require 'spec_helper'

module Qernel
  describe Qernel::ConverterApi, 'network calculations' do
    let(:attrs) {{
      capacity_distribution: 'network_lv_net_distribution',
      network_capacity_available_in_mw: 74803.2,
      network_capacity_used_in_mw: 23376.0
    }}

    let(:api) { converter.query }

    before do
      api.stub_chain(:graph, :area, :area_code).and_return('nl')
    end

    context 'general' do
      let(:converter) do
        Qernel::Converter.new(id:1).with(attrs)
      end

      context 'with no peak' do
        let(:value) { api.required_additional_network_capacity_in_mw(0) }

        it 'returns zero' do
          expect(value).to be_zero
        end
      end

      context 'with sufficient capacity' do
        let(:value) { api.required_additional_network_capacity_in_mw(0) }

        it 'returns zero' do
          expect(value).to be_zero
        end
      end

      context 'with partially sufficient capacity' do
        let(:value) { api.required_additional_network_capacity_in_mw(80000) }

        # individual loads:
        #
        # [ 1398.25,760.09, 514.64, 367.37,
        #   220.1, 121.92, 23.74, 0.0, 0.0, ... ]

        it 'returns a value' do
          expect(value).to be_within(1e-2).of(3406.11)
        end
      end

      context 'with insufficient capacity' do
        let(:value) { api.required_additional_network_capacity_in_mw(100000) }

        # individual loads:
        #
        # [ 2398.25, 1760.09, 1514.64, 1367.37, 1220.10,
        #   1121.92, 1023.74,  925.56,  876.47,  778.29,
        #    729.20,  680.12,  581.94,  532.85,  483.76,
        #    434.67,  336.49,  287.40,  238.31,  140.13 ]

        it 'returns a value' do
          expect(value).to be_within(1e-2).of(17431.29)
        end
      end

      context 'with a huge deficit in capacity' do
        let(:value) { api.required_additional_network_capacity_in_mw(1000000) }

        # individual loads:
        #
        #  [ 47398.25, 46760.09, 46514.64, 46367.37, 46220.10,
        #    46121.92, 46023.74, 45925.56, 45876.47, 45778.29,
        #    45729.20, 45680.12, 45581.94, 45532.85, 45483.76,
        #    45434.67, 45336.49, 45287.40, 45238.31, 45140.13 ]

        it 'returns a value' do
          expect(value).to be_within(1e-2).of(917431.29)
        end
      end
    end

    context 'with no capacity_distribution' do
      let(:converter) do
        Qernel::Converter.new(id:1)
          .with(attrs.except(:capacity_distribution))
      end

      it 'raises an exception' do
        expect do
          api.required_additional_network_capacity_in_mw(10)
        end.to raise_error(/doesn't define a `capacity_distribution'/)
      end
    end # with no capacity distribution

    context "when the distribution CSV doesn't exist" do
      let(:converter) do
        Qernel::Converter.new(id:1)
          .with(attrs.merge(capacity_distribution: :nope))
      end

      it 'returns 0.0' do
        expect(api.required_additional_network_capacity_in_mw(10))
          .to eq(0.0)
      end
    end # with no capacity distribution
  end # network calculations
end
