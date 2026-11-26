# frozen_string_literal: true

require 'spec_helper'

# Only admins with the scenarios:delete scope may delete scenarios. A scenario_access grant, even
# one granting write access, does not allow deleting.
describe 'Deleting a scenario with API v3' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let!(:scenario) { create(:scenario, bound: true) }
  let(:user) { create(:user) }

  def delete_scenario(headers)
    delete "/api/v3/scenarios/#{scenario.id}", headers:
  end

  shared_examples_for 'a refused delete' do |status|
    it "returns #{status}" do
      delete_scenario(headers)
      expect(response).to have_http_status(status)
    end

    it 'does not delete the scenario' do
      expect { delete_scenario(headers) }.not_to change(Scenario, :count)
    end
  end

  shared_examples_for 'an accepted delete' do
    it 'returns 200' do
      delete_scenario(headers)
      expect(response).to have_http_status(:ok)
    end

    it 'deletes the scenario' do
      expect { delete_scenario(headers) }.to change(Scenario, :count).by(-1)
    end
  end

  context 'when the scenario is public' do
    context 'without a token' do
      let(:headers) { {} }

      it_behaves_like 'a refused delete', :forbidden
    end

    context 'when the token has no grant for the scenario' do
      let(:headers) { access_token_header(user, :delete) }

      it_behaves_like 'a refused delete', :forbidden
    end

    context 'when the token grants read access (viewer)' do
      let(:headers) do
        access_token_header(user, :delete, scenario_access: scenario_grant(read: [scenario.id]))
      end

      it_behaves_like 'a refused delete', :forbidden
    end

    context 'when the token grants write access' do
      let(:headers) do
        access_token_header(user, :delete, scenario_access: scenario_grant(write: [scenario.id]))
      end

      it_behaves_like 'a refused delete', :forbidden
    end

    context 'when an admin token has the scenarios:delete scope' do
      let(:headers) { access_token_header(create(:user, admin: true), :delete) }

      it_behaves_like 'an accepted delete'
    end

    context 'when an admin token lacks the scenarios:delete scope' do
      let(:headers) { access_token_header(create(:user, admin: true), :write) }

      it_behaves_like 'a refused delete', :forbidden
    end
  end

  context 'when the scenario is private' do
    before { scenario.update!(private: true) }

    context 'when the token has no grant for the scenario' do
      let(:headers) { access_token_header(user, :delete) }

      it_behaves_like 'a refused delete', :not_found
    end

    context 'when the token grants read access (viewer)' do
      let(:headers) do
        access_token_header(user, :delete, scenario_access: scenario_grant(read: [scenario.id]))
      end

      it_behaves_like 'a refused delete', :not_found
    end

    context 'when the token grants write access' do
      let(:headers) do
        access_token_header(user, :delete, scenario_access: scenario_grant(write: [scenario.id]))
      end

      it_behaves_like 'a refused delete', :not_found
    end

    context 'when an admin token has the scenarios:delete scope' do
      let(:headers) { access_token_header(create(:user, admin: true), :delete) }

      it_behaves_like 'an accepted delete'
    end
  end
end
