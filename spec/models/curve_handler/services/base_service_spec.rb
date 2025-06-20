require 'spec_helper'

RSpec.describe CurveHandler::Services::BaseService do
  # Expose private methods for testing purposes
  let(:klass) do
    Class.new(described_class) do
      public :attached_keys, :user_curve, :bool, :find_config!, :find_curve!, :process
    end
  end

  let(:scenario) { instance_double('Scenario') }
  let(:params)   { ActionController::Parameters.new(id: id_param, include_internal: include_internal, include_unattached: include_unattached) }
  let(:metadata) { { foo: 'bar' } }
  let(:service)  { klass.new(scenario, params, metadata) }

  let(:id_param)          { 'curve_key_curve' }
  let(:include_internal)  { 'true' }
  let(:include_unattached){ 'false' }

  describe '#attached_keys' do
    it 'memoizes and returns scenario.attached_curve_keys' do
      expect(scenario).to receive(:attached_curve_keys).once.and_return(['a', 'b'])
      expect(service.attached_keys).to eq(['a', 'b'])
      # second call should not invoke scenario again
      expect(service.attached_keys).to eq(['a', 'b'])
    end
  end

  describe '#user_curve' do
    it 'returns scenario.attached_curve' do
      expect(scenario).to receive(:attached_curve).with('db_key').and_return(:curve)
      expect(service.user_curve('db_key')).to eq(:curve)
    end
  end

  describe '#bool' do
    context 'truthy strings' do
      it 'casts to boolean true' do
        expect(service.bool(:include_internal)).to be true
      end
    end

    context 'falsy strings or missing keys' do
      it 'casts to boolean false' do
        expect(service.bool(:include_unattached)).to be false
        expect(service.bool(:nonexistent)).to be false
      end
    end
  end

  describe '#find_config!' do
    it 'strips _curve suffix and calls Config.find' do
      config_double = double('Config')
      expect(CurveHandler::Config).to receive(:find).with('curve_key').and_return(config_double)
      expect(service.find_config!).to eq config_double
    end
  end

  describe '#find_curve!' do
    let(:config)     { double('Config', db_key: 'db_key') }
    let(:user_curve) { instance_double('UserCurve', loadable_curve?: loadable) }

    subject { service.find_curve!(config) }

    context 'when user_curve is loadable' do
      let(:loadable) { true }

      it 'returns the user_curve' do
        expect(scenario).to receive(:attached_curve).with('db_key').and_return(user_curve)
        is_expected.to eq(user_curve)
      end
    end

    context 'when user_curve is not loadable' do
      let(:loadable) { false }

      it 'raises ActiveRecord::RecordNotFound' do
        expect(scenario).to receive(:attached_curve).with('db_key').and_return(user_curve)
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#process' do
    let(:raw_series) { [1, 2, 3] }
    let(:uc)         { instance_double('UserCurve', scenario: scenario) }
    let(:cfg) do
      double('Config', processor_key: processor_key, input_keys: ['x_key', 'y_key'])
    end

    subject { service.process(raw_series, uc, cfg) }

    context 'when processor_key is not capacity_profile' do
      let(:processor_key) { :generic }

      it 'returns the raw series unchanged' do
        is_expected.to eq(raw_series)
      end
    end

    context 'when processor_key is capacity_profile' do
      let(:processor_key) { :capacity_profile }

      before do
        allow(uc.scenario).to receive(:user_values).and_return({ 'y_key' => full_load })
      end

      context 'with full load hours present' do
        let(:full_load) { 10 }

        it 'calls Reducers::Rescaler and returns result' do
          reducer = instance_double('CurveHandler::Reducers::Rescaler', call: :rescaled)
          expect(CurveHandler::Reducers::Rescaler).to receive(:new).with(raw_series, 10).and_return(reducer)
          is_expected.to eq(:rescaled)
        end
      end

      context 'with missing full load hours' do
        let(:full_load) { nil }

        it 'returns the raw series unchanged' do
          expect(CurveHandler::Reducers::Rescaler).not_to receive(:new)
          is_expected.to eq(raw_series)
        end
      end
    end
  end
end
