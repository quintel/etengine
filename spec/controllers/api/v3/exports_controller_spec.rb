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
      expect(response.body).to eq(Export::NodeFlowSerializer.new(scenario.gql.future.graph, 'MJ').as_csv)
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
      expect(response.body).to eq(Export::NodeFlowSerializer.new(scenario.gql.present.graph, 'MJ').as_csv)
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
        Export::NodeFlowSerializer.new(scenario.gql.future.molecules, 'kg').as_csv
      )
    end
  end

  describe 'GET electricity_capacities.csv' do
    let(:rows) do
      [%w[key installed_capacity peak_capacity], ['wind_turbine.output (MW)', 8.0, 200.0]]
    end

    before do
      request.headers.merge!(headers)
      allow(Export::ElectricityCapacitiesCSVSerializer).to receive(:new).and_return(
        instance_double(
          Export::ElectricityCapacitiesCSVSerializer,
          filename: :electricity_capacities,
          to_csv_rows: rows
        )
      )
      get :electricity_capacities, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition'])
        .to include("electricity_capacities.#{scenario.id}.csv")
    end

    it 'renders the capacity rows' do
      expect(response.body).to include('wind_turbine.output (MW)')
      expect(response.body).to include('installed_capacity')
    end
  end

  describe 'GET district_heating_capacities.csv' do
    let(:rows) do
      [%w[key installed_capacity peak_capacity], ['heat_network_lt_heatpump.output (MW)', 4.0, 12.0]]
    end

    before do
      request.headers.merge!(headers)
      allow(Export::DistrictHeatingParticipantCapacitiesCSVSerializer).to receive(:new).and_return(
        instance_double(
          Export::DistrictHeatingParticipantCapacitiesCSVSerializer,
          filename: :district_heating_capacities,
          to_csv_rows: rows
        )
      )
      get :district_heating_capacities, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition'])
        .to include("district_heating_capacities.#{scenario.id}.csv")
    end
  end

  describe 'GET direct_emissions_present.csv' do
    before do
      request.headers.merge!(headers)
      get :direct_emissions_present, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("direct_emissions_present.#{scenario.id}.csv")
    end
  end

  describe 'GET direct_emissions_future.csv' do
    before do
      request.headers.merge!(headers)
      get :direct_emissions_future, params: { id: scenario.id }, format: :csv
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("direct_emissions_future.#{scenario.id}.csv")
    end
  end
end
