require 'spec_helper'

RSpec.describe CurveHandler::Serializers::CurveSerializer do
  let(:params)   { ActionController::Parameters.new(id: 'key_curve') }
  let(:scenario) { instance_double('Scenario') }
  let(:curve)    { double('Curve', to_a: [1, 2, 3]) }
  let(:uc) do
    instance_double(
      'UserCurve',
      curve: curve,
      name: name,
      key: 'key',
      scenario: scenario
    )
  end
  let(:serializer_double) { instance_double('Serializer', as_json: { name: 'test' }) }
  let(:config) do
    double(
      'Config',
      db_key: 'key',
      serializer: double(new: serializer_double),
      input_keys: ['x'],
      processor_key: processor_key
    )
  end

  subject(:service) { described_class.new(scenario, params) }

  before do
    allow(uc).to receive(:loadable_curve?).and_return(true)
    allow(CurveHandler::Config).to receive(:find).with('key').and_return(config)
    allow(scenario).to receive(:attached_curve).with('key').and_return(uc)
  end

  context 'when processor_key is not capacity_profile' do
    let(:processor_key) { :generic }
    let(:name)          { 'Name' }

    it 'returns raw series, JSON, and filename' do
      result = service.call
      expect(result.series).to eq([1, 2, 3])
      expect(result.json).to eq({ name: 'test' })
      expect(result.filename).to eq('Name.csv')
    end
  end

  context 'when processor_key is capacity_profile' do
    let(:processor_key) { :capacity_profile }
    let(:name)          { nil }

    before do
      allow(uc.scenario).to receive(:user_values).and_return({ 'x' => full_load })
    end

    context 'with full load hours present' do
      let(:full_load) { 10 }

      it 'rescales series' do
        reducer = instance_double('CurveHandler::Reducers::Rescaler', call: [10, 20, 30])
        expect(CurveHandler::Reducers::Rescaler)
          .to receive(:new).with([1, 2, 3], 10).and_return(reducer)

        result = service.call
        expect(result.series).to eq([10, 20, 30])
        expect(result.filename).to eq('key.csv')
      end
    end

    context 'with missing full load hours' do
      let(:full_load) { nil }

      it 'returns raw series' do
        expect(CurveHandler::Reducers::Rescaler).not_to receive(:new)
        result = service.call
        expect(result.series).to eq([1, 2, 3])
      end
    end
  end
end
