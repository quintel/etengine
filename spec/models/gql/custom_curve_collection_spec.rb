# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gql::CustomCurveCollection do
  let(:collection) { described_class.from_scenario(scenario) }
  let(:scenario) { FactoryBot.create(:scenario) }

  context 'with a scenario containing two valid attachments' do
    before do
      %w[price_curve random_curve].each.with_index do |file, index|
        CurveHandler::AttachService.new(
          CurveHandler::Config.find(Etsource::Config.user_curves.keys[index]),
          fixture_file_upload("#{file}.csv", 'text/csv'),
          scenario
        ).call
      end
    end

    it 'has two curves' do
      expect(collection.length).to eq(2)
    end

    it 'contains both curves' do
      expect(collection.keys).to eq([
        Etsource::Config.user_curves.keys[0],
        Etsource::Config.user_curves.keys[1]
      ])
    end

    it 'has the first user curve values' do
      expect(collection.fetch(Etsource::Config.user_curves.keys[0])).to eq(
        File.read('spec/fixtures/files/price_curve.csv').lines.map(&:to_f)
      )
    end

    it 'has the second user curve values' do
      expect(collection.fetch(Etsource::Config.user_curves.keys[1])).to eq(
        File.read('spec/fixtures/files/random_curve.csv').lines.map(&:to_f)
      )
    end
  end

  context 'with a scenario containing an unconfigured attachment' do
    before do
      attachment = CurveHandler::AttachService.new(
        CurveHandler::Config.find(Etsource::Config.user_curves.keys[0]),
        fixture_file_upload('price_curve.csv', 'text/csv'),
        scenario
      ).call

      attachment.key = 'invalid'
      attachment.save(validate: false)
    end

    it 'has does not contain the invalid curve' do
      expect(collection.length).to eq(0)
    end
  end
end
