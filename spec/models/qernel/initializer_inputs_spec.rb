require 'spec_helper'

describe Qernel::InitializerInputs do
  let(:inputs) { Qernel::InitializerInputs.new('ameland') }

  it 'should sort on priority' do
    expect(inputs.all.keys.map(&:priority)).to eq([2, 0])
  end

  it 'does not contain bar_demand' do
    expect(inputs.all.keys.map(&:key)).to_not include('bar_demand')
  end
end
