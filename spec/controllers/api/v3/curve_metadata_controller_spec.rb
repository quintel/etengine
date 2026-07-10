# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::CurveMetadataController do
  describe 'GET curves' do
    before do
      get :curves, format: :json
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to application/json' do
      expect(response.media_type).to eq('application/json')
    end

    it 'returns hourly_outputs key' do
      json = JSON.parse(response.body)
      expect(json).to have_key('hourly_outputs')
    end

    it 'returns an array of curve metadata' do
      json = JSON.parse(response.body)
      expect(json['hourly_outputs']).to be_an(Array)
      expect(json['hourly_outputs']).not_to be_empty
    end

    it 'includes electricity_profiles in the response' do
      json = JSON.parse(response.body)
      curve = json['hourly_outputs'].find { |c| c['name'] == 'electricity_profiles' }

      expect(curve).not_to be_nil
      expect(curve['name']).to eq('electricity_profiles')
      expect(curve['type']).to eq('merit_curve')
      expect(curve['description']).to be_present
    end

    it 'includes all expected curve attributes' do
      json = JSON.parse(response.body)
      curve = json['hourly_outputs'].first

      expect(curve).to have_key('name')
      expect(curve).to have_key('type')
      expect(curve).to have_key('description')
    end

    it 'includes all known curve names' do
      json = JSON.parse(response.body)
      curve_names = json['hourly_outputs'].map { |c| c['name'] }

      expected_names = [
        'electricity_profiles',
        'electricity_price',
        'district_heating_profiles',
        'agriculture_heat',
        'household_heat',
        'buildings_heat',
        'hydrogen_profiles',
        'network_gas_profiles',
        'residual_load',
        'hydrogen_integral_cost'
      ]

      expect(curve_names).to match_array(expected_names)
    end
  end

  describe 'GET exports' do
    before do
      get :exports, format: :json
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'sets the content type to application/json' do
      expect(response.media_type).to eq('application/json')
    end

    it 'returns annual_exports key' do
      json = JSON.parse(response.body)
      expect(json).to have_key('annual_exports')
    end

    it 'returns an array of export metadata' do
      json = JSON.parse(response.body)
      expect(json['annual_exports']).to be_an(Array)
      expect(json['annual_exports']).not_to be_empty
    end

    it 'includes energy_flow in the response' do
      json = JSON.parse(response.body)
      export = json['annual_exports'].find { |e| e['name'] == 'energy_flow' }

      expect(export).not_to be_nil
      expect(export['name']).to eq('energy_flow')
      expect(export['description']).to be_present
    end

    it 'includes all expected export attributes' do
      json = JSON.parse(response.body)
      export = json['annual_exports'].first

      expect(export).to have_key('name')
      expect(export).to have_key('description')
    end

    it 'includes all known export names' do
      json = JSON.parse(response.body)
      export_names = json['annual_exports'].map { |e| e['name'] }

      expected_names = [
        'energy_flow',
        'energy_flow_present',
        'molecule_flow',
        'sankey',
        'storage_parameters',
        'costs_parameters',
        'electricity_capacities',
        'hydrogen_capacities',
        'network_gas_capacities',
        'district_heating_capacities'
      ]

      expect(export_names).to match_array(expected_names)
    end
  end
end
