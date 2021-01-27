# frozen_string_literal: true

require 'spec_helper'
require_relative './custom_curve_shared_examples'

describe CustomProfileCurveSerializer do
  let(:attachment) { FactoryBot.create(:scenario_attachment, key: 'some_profile_curve') }

  include_examples 'a custom curve Serializer'

  context 'with an attached curve and a "reduce" config' do
    let(:json) { described_class.new(attachment).as_json }

    before do
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/capacity_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    pending { expect(json[:stats]).to include(full_load_hours: 6570.0, length: 8760) }
  end

  context 'with an attached curve and no "reduce" config' do
    let(:attachment) do
      FactoryBot.create(:scenario_attachment, key: 'some_profile_without_reduce_curve')
    end

    let(:json) { described_class.new(attachment).as_json }

    before do
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    it { expect(json[:stats]).not_to have_key(:full_load_hours) }
  end
end
