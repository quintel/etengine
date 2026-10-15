require 'spec_helper'

describe Inspect::ScenariosController do
  render_views

  let(:admin) { FactoryBot.create :admin }
  let(:scenario) { FactoryBot.create :scenario }

  before { sign_in(admin) }

  describe 'GET show' do
    let!(:user_curve) do
      FactoryBot.create(
        :user_curve,
        scenario: scenario,
        key: 'interconnector_1_price_curve',
        name: 'my_prices.csv'
      )
    end

    before { get :show, params: { api_scenario_id: scenario.id, id: scenario.id } }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'lists the curves attached to the scenario' do
      expect(response.body).to include('interconnector_1_price_curve')
    end

    it 'shows which file each curve was replaced with' do
      expect(response.body).to include('my_prices.csv')
    end

    it 'links to the API endpoint which serves the curve as CSV' do
      expect(response.body).to include(
        api_v3_scenario_custom_curve_path(
          scenario_id: scenario.id,
          id: 'interconnector_1_price',
          format: :csv
        )
      )
    end

    it 'omits sortables which are left at their default' do
      expect(response.body).not_to include('Forecast storage order')
    end
  end

  describe 'GET show, when a sortable has been customised' do
    before do
      ForecastStorageOrder.create!(
        scenario: scenario,
        order: ForecastStorageOrder.default_order.reverse
      )

      get :show, params: { api_scenario_id: scenario.id, id: scenario.id }
    end

    it 'names the sortable' do
      expect(response.body).to include('Forecast storage order')
    end

    it 'lists the order the user chose' do
      expect(response.body).to include(ForecastStorageOrder.default_order.last)
    end

    it 'counts it in the section heading' do
      expect(response.body).to include('1 sortable')
    end
  end

  describe 'GET show, when no curves are attached' do
    before { get :show, params: { api_scenario_id: scenario.id, id: scenario.id } }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'omits the curves table' do
      expect(response.body).not_to include('Custom curve')
    end

    it 'marks every section as having no updates' do
      expect(response.body.scan('No updates').length).to eq(4)
    end
  end
end
