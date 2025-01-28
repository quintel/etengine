# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 get gqueries' do
  let(:json) { JSON.parse(response.body) }
  let(:gquery_attributes) do
    {
      'key' => gquery.key,
      'description' => gquery.description,
      'unit' => gquery.unit,
      'labels' => gquery.labels
    }
  end
  let(:user) { create(:user) }
  let(:headers) { access_token_header(user, :write) }

  context 'with no label filters' do
    before { get('/api/v3/gqueries', headers: headers) }

    let(:gquery) { Gquery.all.first }

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

  context 'with one label filter' do
    before { get '/api/v3/gqueries', params: { labels: [gquery.labels.last] }, headers: headers }

    let(:gquery) { Gquery.all.select{|q| q.key == 'some_demand' }.first }

    it 'is successful' do
      expect(response.status).to be(200)
    end

    it 'returns a list of filtered gqueries' do
      expect(json.length).not_to eq(Gquery.all.size)
    end

    it 'contains the correct info on a gquery' do
      expect(json).to include(gquery_attributes)
    end
  end
end
