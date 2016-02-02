require 'spec_helper'

describe Api::V3::FlexibilityOrdersController do
  let(:scenario_id) { 5 }
  let(:create_flexibility_order) {
    post :set, scenario_id: scenario_id, flexibility_order: {
      order: ['p2h', 'p2g']
    }
  }

  describe "new flexibility order" do
    it 'saves a flexibility order' do
      create_flexibility_order

      expect(FlexibilityOrder.count).to eq(1)
    end

    it 'stores the order' do
      create_flexibility_order

      expect(FlexibilityOrder.last.order).to eq(['p2h', 'p2g'])
    end
  end

  describe "existing flexibility order" do
    let!(:flexibility_order) {
      FlexibilityOrder.create!(
        scenario_id: scenario_id, order: ['p2g', 'p2h']
      )
    }

    it 'updates the existing order' do
      create_flexibility_order

      expect(FlexibilityOrder.first.order).to eq(['p2h', 'p2g'])
    end

    it 'count stays at 1' do
      create_flexibility_order

      expect(FlexibilityOrder.count).to eq(1)
    end

    it 'grabs the current flexibility order' do
      get :get, scenario_id: scenario_id

      expect(JSON.parse(response.body)['order']).to eq(['p2g', 'p2h'])
    end
  end

  it "grabs the default order" do
    get :get, scenario_id: -1

    expect(JSON.parse(response.body)['order']).to eq(%w(
      power_to_power electric_vehicle power_to_gas power_to_heat export
    ))
  end
end
