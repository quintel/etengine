# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'a successful CurveHandler::DetachService' do
  it 'returns true' do
    expect(service.call(attachment)).to be(true)
  end

  it 'removes the attachment' do
    expect { service.call(attachment) }
      .to change { scenario.reload.attachments.count }.from(1).to(0)
  end
end

shared_examples_for 'a blob-removing CurveHandler::DetachService' do
  it 'removes the blob' do
    blob_id = attachment.file.blob.id

    # binding.pry

    expect { service.call(attachment) }
      .to change { ActiveStorage::Blob.find_by(id: blob_id) }
      .from(attachment.file.blob).to(nil)
  end
end

RSpec.describe CurveHandler::DetachService do
  let(:file) do
    fixture_file_upload('price_curve.csv', 'text/csv')
  end

  let(:scenario) do
    FactoryBot.create(:scenario, user_values: { unaffected: 1.0 })
  end

  # Config used when adding the attachment. This may be set differently to `config`, for example
  # when testing than an attached file no longer has a matching configuration.
  let(:attach_config) do
    config
  end

  let!(:attachment) do
    CurveHandler::AttachService.new(attach_config, file, scenario, {}).call.tap do |attachment|
      attachment.scenario.reload
    end
  end

  let(:service) do
    described_class.new(config)
  end

  context 'with an attached curve and no reducer' do
    let(:config) { CurveHandler::Config.new(:generic, :generic) }

    include_examples 'a successful CurveHandler::DetachService'
    include_examples 'a blob-removing CurveHandler::DetachService'

    it 'does not change the scenario inputs' do
      expect { service.call(attachment) }.not_to(change { scenario.reload.user_values })
    end
  end

  context 'with an attached curve and a reducer setting two inputs' do
    let(:file) do
      fixture_file_upload('capacity_curve.csv', 'text/csv')
    end

    let(:config) do
      CurveHandler::Config.new(
        :generic,
        :capacity_profile,
        :full_load_hours,
        %w[input_one input_two]
      )
    end

    include_examples 'a successful CurveHandler::DetachService'
    include_examples 'a blob-removing CurveHandler::DetachService'

    it 'removes the affected scenario inputs' do
      expect { service.call(attachment) }
        .to change { scenario.reload.user_values }
        .from({ 'input_one' => 6570.0, 'input_two' => 6570.0, 'unaffected' => 1.0 })
        .to({ 'unaffected' => 1.0 })
    end
  end

  context 'with an attached curve, reducer setting two inputs, but one input is not set' do
    let(:file) do
      fixture_file_upload('capacity_curve.csv', 'text/csv')
    end

    let(:config) do
      CurveHandler::Config.new(
        :generic,
        :capacity_profile,
        :full_load_hours,
        %w[input_one input_two]
      )
    end

    before do
      scenario.reload
      scenario.user_values.delete('input_two')
      scenario.save(validate: true)
    end

    include_examples 'a successful CurveHandler::DetachService'
    include_examples 'a blob-removing CurveHandler::DetachService'

    it 'removes the affected scenario inputs' do
      expect { service.call(attachment) }
        .to change { scenario.reload.user_values }
        .from({ 'input_one' => 6570.0, 'unaffected' => 1.0 })
        .to({ 'unaffected' => 1.0 })
    end
  end

  context 'with an attached curve used by multiple scenario attachments' do
    let(:config) { CurveHandler::Config.new(:generic, :generic) }

    before do
      FactoryBot.create(:scenario, scenario_id: scenario.id)
    end

    include_examples 'a successful CurveHandler::DetachService'

    it 'does not remove the blob' do
      blob_id = attachment.file.blob.id

      expect { service.call(attachment) }
        .not_to change { ActiveStorage::Blob.find_by(id: blob_id) }
        .from(attachment.file.blob)
    end
  end

  context 'without a config' do
    let(:attach_config) { CurveHandler::Config.new(:generic, :generic) }
    let(:config) { nil }

    include_examples 'a successful CurveHandler::DetachService'
    include_examples 'a blob-removing CurveHandler::DetachService'

    it 'does not change the scenario inputs' do
      expect { service.call(attachment) }.not_to(change { scenario.reload.user_values })
    end
  end
end
