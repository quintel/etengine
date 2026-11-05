# frozen_string_literal: true

require 'spec_helper'

describe StableMove::Export do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:missing_id) { Scenario.maximum(:id).to_i + 100 }

  let(:plan) do
    {
      'version' => '2027.01',
      'from_version' => 'latest',
      'engine' => {
        'scenario_ids' => [scenario.id, missing_id],
        'protect' => [scenario.id],
        'area_codes' => { scenario.id.to_s => 'de', missing_id.to_s => 'nl' },
        'roles' => {}
      }
    }
  end

  let(:io) { StringIO.new(''.b) }

  before { allow(Settings).to receive(:version_tag).and_return('latest') }

  def messages
    io.rewind
    MessagePack::Unpacker.new(Zlib::GzipReader.new(io)).each.to_a
  end

  it 'lists the scenarios this engine does not have' do
    expect(described_class.new(plan, io).call['missing_scenarios']).to eq([missing_id])
  end

  it 'lists the scenarios whose area code differs from MyETM' do
    expect(described_class.new(plan, io).call['area_mismatches'])
      .to eq([{ 'scenario_id' => scenario.id, 'myetm' => 'de', 'engine' => 'nl' }])
  end

  it 'writes a header, the rows and an end record with the counts' do
    described_class.new(plan, io).call

    expect(messages.pluck('type')).to eq(%w[header rows end])
  end

  it 'writes the scenarios MyETM protects as keep_compatible' do
    described_class.new(plan, io).call
    rows = messages.find { |message| message['table'] == 'scenarios' }

    expect(rows['rows'].first[rows['columns'].index('keep_compatible')]).to eq('1')
  end

  it 'refuses a plan that moves scenarios from another version' do
    allow(Settings).to receive(:version_tag).and_return('2025.01')

    expect { described_class.new(plan, io).call }.to raise_error(StableMove::Error, /from latest/)
  end
end
