# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V3::UserSortablesController, type: :controller do
  let(:scenario) { create(:scenario) }
  let(:user)     { create(:user) }
  let(:headers)  { access_token_header(user, :write) }

  before do
    request.headers.merge!(headers)
  end

  describe 'GET #index' do
    context 'when no custom orders have been modified' do
      before do
        get :index, params: { scenario_id: scenario.id }
      end

      it 'returns HTTP 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns all five top-level keys plus heat_network sub-keys, each as an Array' do
        json = JSON.parse(response.body)

        expect(json.keys).to contain_exactly(
          'forecast_storage',
          'hydrogen_supply',
          'hydrogen_demand',
          'space_heating',
          'heat_network'
        )

        expect(json['forecast_storage']).to be_an(Array)
        expect(json['hydrogen_supply']).to be_an(Array)
        expect(json['hydrogen_demand']).to be_an(Array)
        expect(json['space_heating']).to be_an(Array)

        heat = json['heat_network']
        expect(heat.keys).to contain_exactly('lt', 'mt', 'ht')
        heat.each_value { |arr| expect(arr).to be_an(Array) }
      end
    end
  end

  describe 'GET #show' do
    context 'valid, non-subtyped sortable_type' do
      {
        forecast_storage:        :forecast_storage_order,
        hydrogen_supply:         :hydrogen_supply_order,
        hydrogen_demand:         :hydrogen_demand_order,
        space_heating:           :households_space_heating_producer_order
      }.each do |stype, method_name|
        it "returns 200 and the #{stype} order" do
          get :show,
            params: {
              scenario_id:    scenario.id,
              sortable_type:  stype
            }

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json).to include('order')
          expect(json['order']).to eq(
            scenario.public_send(method_name).order
          )
        end
      end
    end

    context 'heat_network with sub-types' do
      %i[lt mt ht].each do |sub|
        it "returns 200 and heat_network/#{sub} order" do
          get :show,
            params: {
              scenario_id:    scenario.id,
              sortable_type:  :heat_network,
              subtype:        sub
            }

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['order']).to eq(
            scenario.heat_network_order(sub).order
          )
        end
      end
    end

    context 'unknown sortable_type' do
      it 'renders 404 with a Not found error' do
        get :show,
          params: {
            scenario_id:   scenario.id,
            sortable_type: :not_a_type
          }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['errors']).to eq(['Not found'])
      end
    end
  end

  describe 'PUT #update' do
    let(:new_order) { scenario.forecast_storage_order.order.reverse }

    context 'with valid params' do
      it 'updates the order and returns 200' do
        put :update,
          params: {
            scenario_id:   scenario.id,
            sortable_type: :forecast_storage,
            order:         new_order
          }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['order']).to eq(new_order)
        expect(scenario.reload.forecast_storage_order.order).to eq(new_order)
      end
    end

    context 'when the model is invalid' do
      before do
        # force a validation failure
        order_model = scenario.forecast_storage_order
        allow_any_instance_of(order_model.class).to receive(:valid?).and_return(false)
        allow_any_instance_of(order_model.class)
          .to receive_message_chain(:errors, :full_messages)
          .and_return(['failure'])
      end

      it 'returns 422 with the model errors' do
        put :update,
          params: {
            scenario_id:   scenario.id,
            sortable_type: :forecast_storage,
            order:         new_order
          }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('failure')
      end
    end

    context 'with an invalid JSON payload' do
      before do
        allow_any_instance_of(described_class)
          .to receive(:sortable_params)
          .and_raise(NoMethodError.new("undefined method `permit' for nil:NilClass"))
      end

      it 'rescues and returns 400 Invalid JSON payload' do
        put :update,
          params: {
            scenario_id:   scenario.id,
            sortable_type: :forecast_storage,
            order:         'not_an_array'
          }

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Invalid JSON payload')
      end
    end
  end
end
