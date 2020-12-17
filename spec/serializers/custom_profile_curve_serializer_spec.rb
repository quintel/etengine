# frozen_string_literal: true

require 'spec_helper'
require_relative './custom_curve_shared_examples'

describe CustomProfileCurveSerializer do
  let(:attachment) { FactoryBot.create(:scenario_attachment) }

  include_examples 'a custom curve Serializer'

  context 'with an attached curve' do
    let(:json) { described_class.new(attachment).as_json }

    before do
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    it { expect(json[:stats]).to eq({ full_load_hours: 6570.0, length: 8760 }) }
  end
end
