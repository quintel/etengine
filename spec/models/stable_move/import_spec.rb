# frozen_string_literal: true

require 'spec_helper'

describe StableMove::Import do
  let(:outside) { FactoryBot.create(:scenario) }
  let(:history) { FactoryBot.create(:scenario) }
  let(:current) { FactoryBot.create(:scenario, user: FactoryBot.create(:user)) }

  let(:plan) do
    {
      'version' => '2027',
      'from_version' => 'latest',
      'engine' => {
        'scenario_ids' => [current.id, history.id],
        'protect' => [current.id],
        'area_codes' => {}
      }
    }
  end

  let(:file) do
    io = StringIO.new(''.b)
    StableMove::Export.new(plan, io).call
    io.rewind
    io
  end

  let(:user_values) { { 'households_number_of_residences' => 1.5 } }

  before do
    # The import works on every scenario in the engine, so the examples start without any, also
    # without the one db:seed creates. The scenarios above are created from here on.
    Scenario.delete_all

    allow(Settings).to receive(:version_tag).and_return('latest')

    current.update_columns(user_values:, preset_scenario_id: history.id)
    history.update_columns(preset_scenario_id: outside.id)

    FactoryBot.create(:user_curve, scenario: current).update_columns(source_scenario_id: outside.id)
    HeatNetworkOrder.create!(scenario: current, order: Etsource::Config.heat_network_order_ht)

    attachment = ScenarioAttachment.create!(scenario: current, key: 'esdl_file')
    attachment.file.attach(io: StringIO.new('<esdl/>'), filename: 'energy_system.esdl')

    file

    allow(Settings).to receive(:version_tag).and_return('2027')
  end

  def import
    described_class.new(file).call
  end

  it 'replaces the scenarios with those in the file, keeping their ids' do
    import
    expect(Scenario.pluck(:id)).to contain_exactly(current.id, history.id)
  end

  it 'keeps the scenario values' do
    import
    expect(Scenario.find(current.id).user_values).to eq(user_values)
  end

  it 'keeps a preset that moves along' do
    import
    expect(Scenario.find(current.id).preset_scenario_id).to eq(history.id)
  end

  it 'clears a preset that does not move' do
    import
    expect(Scenario.find(history.id).preset_scenario_id).to be_nil
  end

  it 'sets keep_compatible on the protected scenarios' do
    import
    expect(Scenario.find(current.id)).to have_attributes(keep_compatible: true)
  end

  it 'copies the curves, clearing a source that does not move' do
    import
    expect(UserCurve.find_by(scenario_id: current.id))
      .to have_attributes(curve: Merit::Curve.new([1.0] * 8760).to_a, source_scenario_id: nil)
  end

  it 'copies the other related rows' do
    import
    expect(HeatNetworkOrder.where(scenario_id: current.id).count).to eq(1)
  end

  it 'copies the attachment files' do
    import
    expect(ScenarioAttachment.find_by(scenario_id: current.id).file.download).to eq('<esdl/>')
  end

  it 'reports the scenarios not in the plan that were deleted' do
    expect(import).to include(
      '2027 cleanup in ETEngine (created while hidden): 3',
      '   - 1 not in the plan: test data, deleted'
    )
  end

  it 'imports the same file again' do
    import
    file.rewind

    expect(import).to include(
      '2027 cleanup in ETEngine (created while hidden): 2',
      '   - 2 in the plan: replaced by their copy in the file'
    )
  end

  it 'previews what it would delete and bring' do
    expect(described_class.new(file).preview).to include(
      a_string_starting_with('Importing into 2027 the export from latest'),
      "Scenarios in the file: 2 of the plan's 2",
      '2027 cleanup in ETEngine (created while hidden): 3',
      '   - 1 not in the plan: test data, deleted'
    )
  end

  it 'changes nothing on a preview' do
    described_class.new(file).preview
    expect(Scenario.pluck(:id)).to contain_exactly(outside.id, history.id, current.id)
  end

  context 'when a scenario here is newer than the export' do
    let!(:newer) do
      FactoryBot.create(:scenario).tap { |s| s.update_columns(updated_at: 1.hour.from_now) }
    end

    it 'refuses the file and lists the scenario' do
      expect { import }.to raise_error(
        StableMove::Error, /Scenarios newer than the export: 1\n   - #{newer.id}\n\nDelete/
      )
    end

    it 'refuses it on a preview too' do
      expect { described_class.new(file).preview }
        .to raise_error(StableMove::Error, /after the export/)
    end

    it 'leaves the scenarios as they were' do
      expect { import }.to raise_error(StableMove::Error)
      expect(Scenario.count).to eq(4)
    end
  end

  context 'when the file was written by other move code' do
    before { allow(StableMove::Export).to receive(:code_fingerprint).and_return('other') }

    it 'refuses it' do
      expect { import }.to raise_error(StableMove::Error, /runs other move code/)
    end
  end

  context 'when the file is for another version' do
    before { allow(Settings).to receive(:version_tag).and_return('2025.01') }

    it 'refuses it' do
      expect { import }.to raise_error(StableMove::Error, /to 2027,/)
    end
  end

  context 'when the file ends early' do
    let(:truncated) do
      Zlib::GzipReader.new(file).read.then do |raw|
        io = StringIO.new(''.b)
        gzip = Zlib::GzipWriter.new(io)
        gzip.write(raw[0, raw.bytesize / 2])
        gzip.finish
        io.rewind
        io
      end
    end

    it 'leaves the scenarios as they were' do
      expect { described_class.new(truncated).call }.to raise_error(StableMove::Error)
      expect(Scenario.pluck(:id)).to contain_exactly(outside.id, history.id, current.id)
    end
  end
end
