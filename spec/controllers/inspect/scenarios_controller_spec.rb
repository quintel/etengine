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

  describe 'GET index, when a scenario has users' do
    let(:scenario) { FactoryBot.create(:scenario, user: FactoryBot.create(:user, name: 'Ada Owner')) }

    before { get :index, params: { api_scenario_id: scenario.id } }

    it 'does not list them' do
      expect(response.body).not_to include('Ada Owner')
    end
  end
end
