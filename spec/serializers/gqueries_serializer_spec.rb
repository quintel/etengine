# frozen_string_literal: true

require 'spec_helper'

describe GqueriesSerializer do
  subject do
    described_class.new(Gquery.all).as_json
  end

  let(:existing_query_keys) { Gquery.all.map(&:key) }
  let(:gquery) { Gquery.all.first }
  let(:gquery_attributes) do
    {
      'key' => gquery.key,
      'description' => gquery.description,
      'unit' => gquery.unit
    }
  end

  it 'shows all gqueries' do
    expect(subject.length).to eq(existing_query_keys.length)
  end

  it 'contains info on a gquery' do
    expect(subject).to include(gquery_attributes)
  end

  it 'only contains key, description and unit' do
    expect(subject[0].keys).to include('key', 'description', 'unit')
  end
end
