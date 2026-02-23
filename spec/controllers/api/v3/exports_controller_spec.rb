# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ExportController do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:user) { create(:user) }
  let(:headers) { access_token_header(user, :write) }

  describe 'GET energy_flow.csv' do
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

  describe 'GET energy_flow_present.csv' do
    before do
      request.headers.merge!(headers)
      get :energy_flow_present, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("energy_flow_present.#{scenario.id}.csv")
    end

    it 'renders the CSV' do
      expect(response.body).to eq(NodeFlowSerializer.new(scenario.gql.present.graph, 'MJ').as_csv)
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

  describe 'GET emissions.csv' do
    before do
      request.headers.merge!(headers)
      get :emissions, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("emissions.#{scenario.id}.csv")
    end

    it 'renders the CSV' do
      expect(response.body).to eq(EmissionsExportSerializer.new(scenario).as_csv)
    end

    it 'includes the correct headers in the CSV' do
      csv = CSV.parse(response.body)
      expect(csv[0]).to eq([
        'Node',
        'CO2 production [kton CO2-eq]',
        'CO2 capture [kton CO2-eq]',
        'Other GHG emissions [kton CO2-eq]',
        'Total GHG emissions [kton CO2-eq]',
        'Biogenic CO2 emissions [kton CO2-eq]',
        'CO2 emissions end-use allocation [kton CO2-eq]'
      ])
    end

    it 'may include data rows if emissions exist' do
      csv = CSV.parse(response.body)
      # Should have at least header row
      expect(csv.length).to be >= 1

      # First row should be the header
      expect(csv[0][0]).to eq('Node')
    end
  end
end
