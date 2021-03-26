# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 get gqueries' do
  before { get('/api/v3/gqueries') }

  let(:json) { JSON.parse(response.body) }
  let(:gquery) { Gquery.all.first }
  let(:gquery_attributes) do
    {
      'key' => gquery.key,
      'description' => gquery.description,
      'unit' => gquery.unit
    }
  end

  it 'is successful' do
    expect(response.status).to be(200)
  end

  it 'returns a list of all gqueries' do
    expect(json.length).to eq(Gquery.all.size)
  end

  it 'contains the correct info on a gquery' do
    expect(json).to include(gquery_attributes)
  end
end
