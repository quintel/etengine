require 'spec_helper'

describe 'APIv3 Area details' do
  before { get("/api/v3/areas/#{id}") }

  context 'with a valid area ID' do
    let(:id) { 'nl' }

    it 'responds successfully' do
      expect(response).to have_http_status(:ok)
    end

    it 'replies with JSON' do
      expect(response.content_type).to eq('application/json')
    end

    it 'sends the area data' do
      expect(JSON.parse(response.body)).to eq(Area.get(:nl).as_json)
    end
  end

  context 'with an area ID that does not exist' do
    let(:id) { 'nope' }

    it 'responds with not found' do
      expect(response).to have_http_status(:not_found)
    end
  end
end
