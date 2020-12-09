# frozen_string_literal: true

RSpec.shared_examples_for 'a custom curve Serializer' do
  let(:json) { described_class.new(attachment).as_json }

  context 'with an attached curve' do
    before do
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    it { expect(json).to include(name: 'price_curve.csv') }
    it { expect(json).to include(size: 35_040) }
    it { expect(json).to include(date: attachment.file.created_at) }
  end

  context 'with no attached curve' do
    it { expect(json).to eq({}) }
  end
end
