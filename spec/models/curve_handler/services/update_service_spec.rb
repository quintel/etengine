require 'spec_helper'

RSpec.describe CurveHandler::Services::UpdateService do
  let(:file_param)           { double('UploadedFile') }
  let(:params)               { ActionController::Parameters.new(file: file_param) }
  let(:scenario)             { instance_double('Scenario') }
  let(:metadata)             { { foo: 'bar' } }
  let(:serializer_instance)  { instance_double('Serializer', as_json: { name: 'test' }) }
  let(:serializer_class)     { class_double('SomeSerializerClass').as_stubbed_const(new: serializer_instance) }
  let(:config)               { instance_double(CurveHandler::Config, serializer: serializer_class) }
  let(:handler)              { instance_double(CurveHandler::Services::AttachService) }

  subject(:service) { described_class.new(scenario, params) }

  before do
    allow(service).to receive(:find_config!).and_return(config)
    allow(service).to receive(:metadata).and_return(metadata)
    allow(params).to receive(:require).with(:file).and_return(file_param)
    allow(CurveHandler::Services::AttachService)
      .to receive(:new)
      .with(config, file_param, scenario, metadata)
      .and_return(handler)
  end

  context 'when the upload handler is valid' do
    let(:user_curve) { instance_double('UserCurve') }

    before do
      allow(handler).to receive(:valid?).and_return(true)
      allow(handler).to receive(:call).and_return(user_curve)
      allow(serializer_class).to receive(:new).with(user_curve).and_return(serializer_instance)
    end

    it 'calls the handler and returns the serialized JSON' do
      result = service.call

      expect(handler).to have_received(:call)
      expect(result.json).to eq({ name: 'test' })
      expect(result.errors).to be_nil
      expect(result.error_keys).to be_nil
    end
  end

  context 'when the upload handler is invalid' do
    before do
      allow(handler).to receive(:valid?).and_return(false)
      allow(handler).to receive(:errors).and_return(['bad file'])
      allow(handler).to receive(:error_keys).and_return([:file])
    end

    it 'does not call the handler and returns errors and error_keys, without JSON' do
      expect(handler).not_to receive(:call)

      result = service.call

      expect(result.json).to be_nil
      expect(result.errors).to eq(['bad file'])
      expect(result.error_keys).to eq([:file])
    end
  end
end
