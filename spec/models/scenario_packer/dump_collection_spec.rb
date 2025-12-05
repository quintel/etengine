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
      allow(rel).to receive(:any?).and_return(true)
      allow(rel).to receive(:empty?).and_return(false)
      allow(rel).to receive(:count).and_return(ids.count)
      # Support chaining .includes()
      allow(rel).to receive(:includes).and_return(rel)
    end
  end

  before do
    # Stub Scenario.where(id: ids) to return our relation
    allow(Scenario).to receive(:where).with(id: ids).and_return(relation)
    # Also stub Scenario.all and Scenario.accessible_by for validator
    allow(Scenario).to receive(:all).and_return(Scenario)
    allow(Scenario).to receive(:accessible_by).and_return(Scenario)

    # Stub the Dump wrapper
    records.each_with_index do |rec, idx|
      dump = double('ScenarioPacker::Dump')
      allow(dump).to receive(:call).and_return(Dry::Monads::Success(dummy_hashes[idx]))
      allow(ScenarioPacker::Dump).to receive(:new).with(rec).and_return(dump)
    end
  end

  describe '.from_ids' do
    it 'builds a collection from explicit IDs' do
      result = described_class.from_ids(ids)
      expect(result).to be_success

      col = result.value!
      json_result = col.call
      expect(json_result).to be_success
      expect(json_result.value!).to eq(dummy_hashes)

      to_json_result = col.to_json
      expect(to_json_result).to be_success
      expect(to_json_result.value!).to include(dummy_hashes.first[:foo])

      expect(col.filename).to match(/^1-2-3_.*_\d{2}-\d{2}-\d{2}\.json$/)
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
        # Create a separate relation for the where clause that also supports includes
        where_relation = instance_double(ActiveRecord::Relation).tap do |wr|
          allow(wr).to receive(:includes).and_return(relation)
          allow(wr).to receive(:any?).and_return(true)
        end
        allow(usr).to receive(:where)
          .with('scenarios.updated_at >= ?', kind_of(ActiveSupport::TimeWithZone))
          .and_return(where_relation)
      end
    end

    context 'when dump_type is ids' do
      it 'returns a packer for the given IDs' do
        params = ActionController::Parameters.new(
          dump_type:      'ids',
          scenario_ids:   '1, 2,3'
        )
        result = described_class.from_params(params, user)
        expect(result).to be_success

        packer = result.value!
        expect(packer.dump_type).to eq('ids')
        expect(packer.call.value!).to eq(dummy_hashes)
        expect(packer.filename).to match(/^1-2-3_.*_\d{2}-\d{2}-\d{2}\.json$/)
      end

      it 'returns a failure if no IDs are provided' do
        params = ActionController::Parameters.new(
          dump_type:    'ids',
          scenario_ids: ''
        )
        result = described_class.from_params(params, user)
        expect(result).to be_failure
        expect(result.failure.to_s).to match(/at least one valid ID required/)
      end
    end

    context 'when dump_type is featured' do
      let(:featured_scenarios) do
        [
          double('FeaturedScenario', id: 1, title: 'Featured Scenario 1', attributes: { 'id' => 1, 'title' => 'Featured Scenario 1' }),
          double('FeaturedScenario', id: 2, title: 'Featured Scenario 2', attributes: { 'id' => 2, 'title' => 'Featured Scenario 2' }),
          double('FeaturedScenario', id: 3, title: 'Featured Scenario 3', attributes: { 'id' => 3, 'title' => 'Featured Scenario 3' })
        ]
      end

      before do
        allow(MyEtm::FeaturedScenario).to receive(:cached_scenarios).and_return(featured_scenarios)
      end

      it 'returns a packer for featured scenario IDs' do
        params = ActionController::Parameters.new(dump_type: 'featured')
        result = described_class.from_params(params, user)
        expect(result).to be_success

        packer = result.value!
        expect(packer.dump_type).to eq('featured')
        expect(packer.call.value!).to eq(dummy_hashes)
      end
    end

    context 'when dump_type is my_scenarios' do
      it "returns a packer for the user's recently updated scenarios" do
        params = ActionController::Parameters.new(dump_type: 'my_scenarios')
        result = described_class.from_params(params, user)
        expect(result).to be_success

        packer = result.value!
        expect(packer.dump_type).to eq('my_scenarios')
        expect(packer.call.value!).to eq(dummy_hashes)
        expect(packer.filename).to match(/^alice-smith_.*_\d{2}-\d{2}-\d{2}\.json$/)
      end
    end

    context 'with an unknown dump_type' do
      it 'returns a failure' do
        params = ActionController::Parameters.new(dump_type: 'wat')
        result = described_class.from_params(params, user)
        expect(result).to be_failure
        expect(result.failure).to match(/Unknown dump type/)
      end
    end
  end

  describe '#call' do
    it 'filters out missing records' do
      sparse_ids = [1, 99, 2]
      available = records.select { |r| [1, 2].include?(r.id) }

      rel2 = instance_double(ActiveRecord::Relation).tap do |rel|
        allow(rel).to receive(:pluck).with(:id).and_return(sparse_ids)
        allow(rel).to receive(:index_by).and_return(available.index_by(&:id))
        allow(rel).to receive(:any?).and_return(true)
        allow(rel).to receive(:empty?).and_return(false)
        allow(rel).to receive(:count).and_return(available.count)
        allow(rel).to receive(:includes).and_return(rel)
      end
      allow(Scenario).to receive(:where).with(id: sparse_ids).and_return(rel2)

      result = described_class.from_ids(sparse_ids)
      expect(result).to be_success

      col = result.value!
      json_result = col.call
      expect(json_result).to be_success
      expect(json_result.value!).to eq([dummy_hashes[0], dummy_hashes[1]])
    end
  end

  describe '#to_json' do
    it 'returns pretty-printed JSON' do
      result = described_class.from_ids(ids)
      expect(result).to be_success

      col = result.value!
      json_result = col.to_json
      expect(json_result).to be_success

      json = json_result.value!
      expect(JSON.parse(json)).to eq(dummy_hashes.map(&:stringify_keys))
      expect(json).to include("\n  ")  # pretty-printed indentation
    end
  end

  describe '#filename' do
    it 'defaults to hyphenated IDs list' do
      result = described_class.from_ids(ids)
      expect(result).to be_success

      col = result.value!
      expect(col.filename).to match(/^1-2-3_.*_\d{2}-\d{2}-\d{2}\.json$/)
    end
  end
end
