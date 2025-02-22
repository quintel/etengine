# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ExportController do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:user) { create(:user) }
  let(:headers) { access_token_header(user, :write) }

  describe 'GET energy_flows.csv' do
    before do
      request.headers.merge!(headers)
      get :energy_flow, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("energy_flow.#{scenario.id}.csv")
    end

    it 'renders the CSV' do
      expect(response.body).to eq(NodeFlowSerializer.new(scenario.gql.future.graph, 'MJ').as_csv)
    end
  end

  describe 'GET molecule_flows.csv' do
    before do
      request.headers.merge!(headers)
      get :molecule_flow, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("molecule_flow.#{scenario.id}.csv")
    end

    it 'renders the CSV' do
      expect(response.body).to eq(
        NodeFlowSerializer.new(scenario.gql.future.molecules, 'kg').as_csv
      )
    end
  end
end
