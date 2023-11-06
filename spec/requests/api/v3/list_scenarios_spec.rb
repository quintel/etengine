# frozen_string_literal: true

require 'spec_helper'

describe 'Deleting a scenario with API v3' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { create(:scenario) }

  context 'when not authenticated' do
    before do
      get '/api/v3/scenarios'
    end

    it 'returns 403' do
      expect(response.status).to eq(403)
    end
  end

  context 'when authenticated' do
    let(:user) { create(:user) }

    let!(:scenario1) { create(:scenario, user: user, private: false, created_at: 5.minutes.ago) }
    let!(:scenario2) { create(:scenario, user: user, private: true, created_at: 4.minutes.ago) }
    let!(:scenario3) { create(:scenario, user: user, private: false, created_at: 3.minutes.ago) }

    let!(:public_scenario) { create(:scenario) }
    let!(:other_scenario) { create(:scenario, user: create(:user)) }

    let(:json) { JSON.parse(response.body) }

    context 'when the token scope is "public"' do
      before do
        get '/api/v3/scenarios', headers: access_token_header(user, :public)
      end

      it 'returns 200 OK' do
        expect(response.status).to eq(200)
      end

      it 'returns only the user-owned public scenarios' do
        expect(json['data'].pluck('id').sort)
          .to eq([scenario1.id, scenario3.id].sort)
      end
    end

    context 'when the token scope is "scenarios:read"' do
      before do
        get '/api/v3/scenarios', headers: access_token_header(user, :read)
      end

      it 'returns 200 OK' do
        expect(response.status).to eq(200)
      end

      it 'lists the scenarios' do
        expect(json['data'].pluck('id').sort)
          .to eq([scenario3.id, scenario2.id, scenario1.id].sort)
      end

      it 'does not include unowned scenarios' do
        expect(json['data'].pluck('id')).not_to include(public_scenario.id)
      end

      it 'does not include scenarios belonging to other users' do
        expect(json['data'].pluck('id')).not_to include(other_scenario.id)
      end

      it 'does not include a link to the previous page' do
        expect(json['links']['prev']).to be_nil
      end

      it 'does not include a link to the next page' do
        expect(json['links']['next']).to be_nil
      end

      it 'has a count of 3' do
        expect(json['meta']['count']).to eq(3)
      end

      it 'has a total of 3' do
        expect(json['meta']['total']).to eq(3)
      end

      it 'has a limit of 25' do
        expect(json['meta']['limit']).to eq(25)
      end

      it 'has a total_pages of 1' do
        expect(json['meta']['total_pages']).to eq(1)
      end

      it 'has a current_page of 1' do
        expect(json['meta']['current_page']).to eq(1)
      end
    end

    context 'when there are three scenarios and limit=2' do
      before do
        get '/api/v3/scenarios', params: { limit: 2 }, headers: access_token_header(user, :read)
      end

      it 'returns 200 OK' do
        expect(response.status).to eq(200)
      end

      it 'lists the first two scenarios' do
        expect(json['data'].map { |scenario| scenario['id'] }).to eq([scenario3.id, scenario2.id])
      end

      it 'does not include a link to the previous page' do
        expect(json['links']['prev']).to be_nil
      end

      it 'includes a link to the next page' do
        expect(json['links']['next']).to include('page=2')
      end

      it 'has a count of 2' do
        expect(json['meta']['count']).to eq(2)
      end

      it 'has a total of 3' do
        expect(json['meta']['total']).to eq(3)
      end

      it 'has a limit of 2' do
        expect(json['meta']['limit']).to eq(2)
      end

      it 'has a total_pages of 2' do
        expect(json['meta']['total_pages']).to eq(2)
      end

      it 'has a current_page of 1' do
        expect(json['meta']['current_page']).to eq(1)
      end
    end

    context 'when there are three scenarios and limit=2 and offset=2' do
      before do
        get '/api/v3/scenarios',
          params: { limit: 2, page: 2 },
          headers: access_token_header(user, :read)
      end

      it 'returns 200 OK' do
        expect(response.status).to eq(200)
      end

      it 'lists the final scenario' do
        expect(json['data'].map { |scenario| scenario['id'] }).to eq([scenario1.id])
      end

      it 'includes a link to the previous page' do
        expect(json['links']['prev']).to include('page=1')
      end

      it 'does not include a link to the next page' do
        expect(json['links']['next']).to be_nil
      end

      it 'has a count of 1' do
        expect(json['meta']['count']).to eq(1)
      end

      it 'has a total of 3' do
        expect(json['meta']['total']).to eq(3)
      end

      it 'has a limit of 2' do
        expect(json['meta']['limit']).to eq(2)
      end

      it 'has a total_pages of 2' do
        expect(json['meta']['total_pages']).to eq(2)
      end

      it 'has a current_page of 2' do
        expect(json['meta']['current_page']).to eq(2)
      end
    end
  end
end
