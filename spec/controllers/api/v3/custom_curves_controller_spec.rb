# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V3::CustomCurvesController do
  let(:scenario) { FactoryBot.create(:scenario) }

  context 'when no curves are attached' do
    before { get(:index, params: { scenario_id: scenario.id }) }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'returns an empty array' do
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  context 'when no curves are attached and include_unattached is "true"' do
    before { get(:index, params: { scenario_id: scenario.id, include_unattached: 'true' }) }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'returns an array containing the curves' do
      expect(JSON.parse(response.body).length).to be >= 1
    end
  end

  context 'when no curves are attached and include_unattached is "false"' do
    before { get(:index, params: { scenario_id: scenario.id, include_unattached: 'false' }) }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'returns an empty array' do
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  context 'when no curves are attached and include_unattached and include_internal area "true"' do
    before do
      get(
        :index,
        params: { scenario_id: scenario.id, include_unattached: 'true', include_internal: 'true' }
      )
    end

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'returns an array containing the internal' do
      curves = JSON.parse(response.body)
      expect(curves.count { |c| c['key'] == 'internal' }).to eq(1)
    end
  end

  context 'when no curves are attached and include_unattached and include_unattached are "false"' do
    before do
      get(
        :index,
        params: { scenario_id: scenario.id, include_unattached: 'false', include_internal: 'false' }
      )
    end

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'returns an empty array' do
      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
