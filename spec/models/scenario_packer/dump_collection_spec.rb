# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioPacker::DumpCollection do
  let(:ids)    { [1, 2, 3] }
  let(:records) do
    ids.map { |i| double('Scenario', id: i) }
  end
  let(:dummy_hashes) { ids.map { |i| { id: i, foo: "bar#{i}" } } }

  # Fake ActiveRecord::Relation for pluck/index_by
  let(:relation) do
    instance_double(ActiveRecord::Relation).tap do |rel|
      allow(rel).to receive(:pluck).with(:id).and_return(ids)
      allow(rel).to receive(:index_by).and_return(records.index_by(&:id))
    end
  end

  before do
    # Stub Scenario.where(id: ids) to return our relation
    allow(Scenario).to receive(:where).with(id: ids).and_return(relation)

    # Stub the Dump wrapper
    records.each_with_index do |rec, idx|
      dump = double('ScenarioPacker::Dump', as_json: dummy_hashes[idx])
      allow(ScenarioPacker::Dump).to receive(:new).with(rec).and_return(dump)
    end
  end

  describe '.from_ids' do
    it 'builds a collection from explicit IDs' do
      col = described_class.from_ids(ids)
      expect(col.as_json).to eq(dummy_hashes)
      expect(col.to_json      ).to include(dummy_hashes.first[:foo])
      expect(col.filename     ).to eq('1-2-3-dump.json')
    end
  end

  describe '.from_params' do
    let(:user) do
      instance_double(
        User,
        name:      'Alice Smith',
        scenarios: user_scenarios
      )
    end

    # For the my_scenarios case, user.scenarios.where(...) must return our relation
    let(:user_scenarios) do
      instance_double(ActiveRecord::Relation).tap do |usr|
        allow(usr).to receive(:where)
          .with('scenarios.updated_at >= ?', kind_of(ActiveSupport::TimeWithZone))
          .and_return(relation)
      end
    end

    context 'when dump_type is ids' do
      it 'returns a packer for the given IDs' do
        params = ActionController::Parameters.new(
          dump_type:      'ids',
          scenario_ids:   '1, 2,3'
        )
        packer = described_class.from_params(params, user)

        expect(packer.dump_type).to eq('ids')
        expect(packer.as_json  ).to eq(dummy_hashes)
        expect(packer.filename ).to eq('1-2-3-dump.json')
      end

      it 'raises an error if no IDs are provided' do
        params = ActionController::Parameters.new(
          dump_type:    'ids',
          scenario_ids: ''
        )
        expect {
          described_class.from_params(params, user)
        }.to raise_error(ScenarioPacker::DumpCollection::InvalidParamsError,
                         /enter at least one scenario ID/)
      end
    end

    context 'when dump_type is featured' do
      before do
        allow(::MyEtm::FeaturedScenario).to receive(:cached_ids).and_return(ids)
      end

      it 'returns a packer for featured scenario IDs' do
        params = ActionController::Parameters.new(dump_type: 'featured')
        packer = described_class.from_params(params, user)

        expect(packer.dump_type).to eq('featured')
        expect(packer.as_json  ).to eq(dummy_hashes)
        expect(packer.filename ).to eq('featured-dump.json')
      end
    end

    context 'when dump_type is my_scenarios' do
      it 'returns a packer for the user’s recently updated scenarios' do
        params = ActionController::Parameters.new(dump_type: 'my_scenarios')
        packer = described_class.from_params(params, user)

        expect(packer.dump_type).to eq('my_scenarios')
        expect(packer.as_json  ).to eq(dummy_hashes)
        # user_name "Alice Smith" parameterizes to "alice-smith"
        expect(packer.filename ).to eq('alice-smith-dump.json')
      end
    end

    context 'with an unknown dump_type' do
      it 'raises an error' do
        params = ActionController::Parameters.new(dump_type: 'wat')
        expect {
          described_class.from_params(params, user)
        }.to raise_error(ScenarioPacker::DumpCollection::InvalidParamsError,
                         /Unknown dump type/)
      end
    end
  end

  describe '#as_json' do
    it 'filters out missing records' do
      sparse_ids = [1, 99, 2]
      available = records.select { |r| [1, 2].include?(r.id) }

      # Stub a new relation for sparse_ids
      rel2 = instance_double(ActiveRecord::Relation).tap do |rel|
        allow(rel).to receive(:pluck).with(:id).and_return(sparse_ids)
        allow(rel).to receive(:index_by).and_return(available.index_by(&:id))
      end
      allow(Scenario).to receive(:where).with(id: sparse_ids).and_return(rel2)

      col = described_class.from_ids(sparse_ids)
      expect(col.as_json).to eq([dummy_hashes[0], dummy_hashes[1]])
    end
  end

  describe '#to_json' do
    it 'returns pretty-printed JSON' do
      col = described_class.from_ids(ids)
      json = col.to_json
      expect(JSON.parse(json)).to eq(dummy_hashes.map(&:stringify_keys))
      expect(json).to include("\n  ")  # pretty-printed indentation
    end
  end

  describe '#filename' do
    it 'defaults to hyphenated IDs list' do
      col = described_class.from_ids(ids)
      expect(col.filename).to eq('1-2-3-dump.json')
    end
  end
end
