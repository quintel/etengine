# frozen_string_literal: true

require 'spec_helper'

describe 'Deleting a scenario with API v3' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { create(:scenario) }

  context 'when not authenticated' do
    context 'when the scenario is unowned' do
      before do
        delete "/api/v3/scenarios/#{scenario.id}"
      end

      it 'returns 403' do
        expect(response.status).to eq(403)
      end
    end

    context 'when the scenario is owned by someone' do
      before do
        scenario.user = create(:user)
        delete "/api/v3/scenarios/#{scenario.id}"
      end

      it 'returns 403' do
        expect(response.status).to eq(403)
      end
    end

    context 'when the scenario is private' do
      before do
        scenario.delete_all_users
        scenario.user = create(:user)
        scenario.reload.update!(private: true)
        delete "/api/v3/scenarios/#{scenario.id}"
      end

      it 'returns 404' do
        expect(response.status).to eq(404)
      end
    end
  end

  context 'when authenticated' do
    let(:user) { create(:user) }

    context 'when the scenario is unowned' do
      before do
        delete "/api/v3/scenarios/#{scenario.id}", headers: access_token_header(user, :delete)
      end

      it 'returns 403' do
        expect(response.status).to eq(403)
      end
    end

    context 'when the scenario is public and owned by the user' do
      before do
        scenario.delete_all_users
        scenario.user = user
        delete "/api/v3/scenarios/#{scenario.id}", headers: access_token_header(user, :delete)
      end

      it 'returns 200' do
        expect(response.status).to eq(200)
      end
    end

    context 'when the scenario is public and owned by the user but the token lacks scenarios:delete' do
      before do
        scenario.delete_all_users
        scenario.user = user
        delete "/api/v3/scenarios/#{scenario.id}", headers: access_token_header(user, :write)
      end

      it 'returns 403' do
        expect(response.status).to eq(403)
      end
    end

    context 'when the scenario is owned by someone else' do
      before do
        scenario.delete_all_users
        scenario.user = create(:user)
        delete "/api/v3/scenarios/#{scenario.id}", headers: access_token_header(user, :delete)
      end

      it 'returns 403' do
        expect(response.status).to eq(403)
      end
    end

    context 'when the scenario is private and owned by the user' do
      before do
        scenario.delete_all_users
        scenario.user = user
        scenario.reload.update!(private: true)
        delete "/api/v3/scenarios/#{scenario.id}", headers: access_token_header(user, :delete)
      end

      it 'returns 200' do
        expect(response.status).to eq(200)
      end
    end

    context 'when the scenario is private and owned by someone else' do
      before do
        scenario.delete_all_users
        scenario.user = create(:user)
        scenario.reload.update!(private: true)
        delete "/api/v3/scenarios/#{scenario.id}", headers: access_token_header(user, :delete)
      end

      it 'returns 404' do
        expect(response.status).to eq(404)
      end
    end
  end
end
