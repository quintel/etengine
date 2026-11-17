require 'spec_helper'

describe Inspect::ScenariosController do
  render_views

  let(:admin) { FactoryBot.create :admin }

  before { sign_in(admin) }

  describe 'GET show, when the scenario has users' do
    let(:owner) { FactoryBot.create(:user, name: 'Ada Owner') }
    let(:scenario) { FactoryBot.create(:scenario, user: owner) }

    before { get :show, params: { api_scenario_id: scenario.id, id: scenario.id } }

    it 'does not list them' do
      expect(response.body).not_to include('Ada Owner')
    end
  end

  describe 'GET show, for a bound Session with a creator' do
    let(:scenario) { FactoryBot.create(:scenario, creator_id: 4242, bound: true) }

    before { get :show, params: { api_scenario_id: scenario.id, id: scenario.id } }

    it 'links the creator ID to the user in MyETM' do
      expect(response.body).to include(
        %(<a href="#{Settings.identity.issuer}/admin/user/4242">4242</a>)
      )
    end

    it 'shows that it is bound' do
      expect(response.body).to match(%r{<th>Bound</th>\s*<td>Yes</td>})
    end
  end

  describe 'GET index, when a scenario has users' do
    let(:scenario) { FactoryBot.create(:scenario, user: FactoryBot.create(:user, name: 'Ada Owner')) }

    before { get :index, params: { api_scenario_id: scenario.id } }

    it 'does not list them' do
      expect(response.body).not_to include('Ada Owner')
    end
  end
end
