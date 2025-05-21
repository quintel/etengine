require 'spec_helper'

RSpec.describe ScenarioPacker::DumpCollection do
  let(:ids) { [1, 2, 3] }
  let(:records) do
    ids.map do |i|
      double('Scenario', id: i)
    end
  end
  let(:dummy_hashes) { ids.map { |i| { id: i, foo: "bar#{i}" } } }

  before do
    # Stub AR query
    allow(Scenario).to receive(:where).with(id: ids).and_return(records)

    # Stub Dump serializer
    records.each_with_index do |rec, idx|
      dump = double('Dump', as_json: dummy_hashes[idx])
      allow(ScenarioPacker::Dump).to receive(:new).with(rec).and_return(dump)
    end
  end

  describe '#as_json' do
    it 'returns array of scenario hashes in original order' do
      collection = described_class.new(ids)
      expect(collection.as_json).to eq(dummy_hashes)
    end

    it 'filters out missing records' do
      sparse_ids = [1, 99, 2]
      available_records = records.select { |r| sparse_ids.include?(r.id) }

      allow(Scenario).to receive(:where)
        .with(id: sparse_ids)
        .and_return(available_records)

      collection = described_class.new(sparse_ids)
      expected_hashes = [dummy_hashes[0], dummy_hashes[1]]

      expect(collection.as_json).to eq(expected_hashes)
    end
  end

  describe '#to_json' do
    it 'returns pretty-printed JSON string of hashes' do
      json_str = described_class.new(ids).to_json
      parsed = JSON.parse(json_str)

      expect(parsed).to eq(dummy_hashes.map(&:stringify_keys))
    end
  end

  describe '#filename' do
    it 'joins ids with hyphens and appends -dump.json' do
      collection = described_class.new(ids)
      expect(collection.filename).to eq('1-2-3-dump.json')
    end
  end
end
