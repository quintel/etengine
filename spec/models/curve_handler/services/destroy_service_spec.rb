require 'spec_helper'

RSpec.describe CurveHandler::Services::DestroyService do
  let(:params)   { ActionController::Parameters.new(id: 'key_curve') }
  let(:scenario) { instance_double('Scenario') }
  let(:config)   { double('Config', db_key: 'db') }
  subject(:service) { described_class.new(scenario, params) }

  before do
    allow(CurveHandler::Config).to receive(:find).with('key').and_return(config)
  end

  context 'when a user curve is attached' do
    let(:uc) { instance_double('UserCurve') }

    before do
      allow(scenario).to receive(:attached_curve).with('db').and_return(uc)
      allow(CurveHandler::Services::DetachService).to receive(:call).with(uc)
    end

    it 'calls DetachService and returns an empty result' do
      result = service.call
      expect(CurveHandler::Services::DetachService).to have_received(:call).with(uc)
      expect(result.series).to be_nil
      expect(result.json).to be_nil
      expect(result.errors).to be_nil
      expect(result.error_keys).to be_nil
    end
  end

  context 'when no user curve is attached' do
    before do
      allow(scenario).to receive(:attached_curve).with('db').and_return(nil)
      allow(CurveHandler::Services::DetachService).to receive(:call)
    end

    it 'does not call DetachService and returns a result' do
      result = service.call
      expect(CurveHandler::Services::DetachService).not_to have_received(:call)
      expect(result).to be_a(CurveHandler::Result)
    end
  end
end
