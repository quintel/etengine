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

  shared_examples 'a mapping-driven direct emissions export' do
    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to text/csv' do
      expect(response.media_type).to eq('text/csv')
    end

    it 'includes the eight legacy columns, byte-identical to the pre-rework export' do
      expect(CSV.parse(response.body).first).to eq(
        [
          'Sector', 'Subsector', 'Key', 'GHG',
          'CO2 production [kton CO2-eq]', 'CO2 capture [kton CO2-eq]',
          'Other GHG emissions [kton CO2-eq]', 'Total GHG emissions [kton CO2-eq]'
        ]
      )
    end

    it 'renders Sector/Subsector as mapping lookups for a labelled, :emissions-group node' do
      row = CSV.parse(response.body).find { |r| r[2] == 'm_waste' }
      expect(row).to eq(%w[Waste Non-specified m_waste co2 0.0 0.0 0.0 0.0])
    end

    it 'excludes a labelled node whose pair has no value in the require column' do
      expect(CSV.parse(response.body).flatten).not_to include('foo')
    end

    it 'excludes a labelled node that is not in the :emissions group' do
      # `bar`/`baz`/`lft`/`buildings_space_heating_demand` all carry a sector_label/use that
      # matches an exported mapping row, but none is in the :emissions node group.
      expect(CSV.parse(response.body).flatten).not_to include('bar', 'baz', 'lft', 'buildings_space_heating_demand')
    end
  end

  describe 'GET direct_emissions_present.csv' do
    before do
      request.headers.merge!(headers)
      get :direct_emissions_present, params: { id: scenario.id }, format: :csv
    end

    include_examples 'a mapping-driven direct emissions export'

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("direct_emissions_present.#{scenario.id}.csv")
    end
  end

  describe 'GET direct_emissions_future.csv' do
    before do
      request.headers.merge!(headers)
      get :direct_emissions_future, params: { id: scenario.id }, format: :csv
    end

    include_examples 'a mapping-driven direct emissions export'

    it 'sets the CSV filename' do
      expect(response.headers['Content-Disposition']).to include("direct_emissions_future.#{scenario.id}.csv")
    end
  end
end
