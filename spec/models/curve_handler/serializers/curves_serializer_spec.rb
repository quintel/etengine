require 'spec_helper'

RSpec.describe CurveHandler::Serializers::CurvesSerializer do
  let(:attached_keys)      { ['a'] }
  let(:include_internal)   { 'false' }
  let(:include_unattached) { 'false' }
  let(:scenario) do
    instance_double(
      'Scenario',
      attached_curve_keys: attached_keys,
      attached_curve: :ignored
    )
  end
  let(:params) { ActionController::Parameters.new(include_internal: include_internal, include_unattached: include_unattached) }
  let(:cfg1) do
    double(
      'Config',
      db_key: 'a',
      internal?: false,
      serializer: double(new: double(as_json: { foo: 'bar' }))
    )
  end
  let(:cfg2) do
    double(
      'Config',
      db_key: 'b',
      internal?: false,
      serializer: double(new: double(as_json: { baz: 'qux' }))
    )
  end

  before do
    allow(Etsource::Config).to receive(:user_curves).and_return({ 'a' => cfg1, 'b' => cfg2 })
  end

  subject(:service) { described_class.new(scenario, params) }

  describe '#call' do
    context 'with only attached curves' do
      it 'returns only the attached curve JSON' do
        result = service.call
        expect(result.series).to eq([{ foo: 'bar' }])
      end
    end

    context 'when include_unattached is true' do
      let(:include_unattached) { 'true' }
      let(:unattached_json)    { { unattached: true } }

      before do
        allow(UnattachedCustomCurveSerializer)
          .to receive(:new).with(cfg2).and_return(double(as_json: unattached_json))
      end

      it 'includes unattached curve JSON' do
        result = service.call
        expect(result.series).to include(unattached_json)
      end
    end
  end
end
