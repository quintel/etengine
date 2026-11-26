# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 hydrogen orders' do
  let(:valid_options) { HydrogenSupplyOrder.default_order }
  let(:scenario) { create(:scenario, bound: true) }
  let(:url) { api_v3_scenario_hydrogen_supply_order_url(scenario_id: scenario.id) }
  let(:user) { create(:user) }
  let(:headers) do
    access_token_header(user, :write, scenario_access: scenario_grant(write: [scenario.id]))
  end

  context 'when fetching the hydrogen order' do
    let(:request) { get(url, headers: headers) }

    context 'when no order exists' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the default hydrogen order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HydrogenSupplyOrder.default_order
        )
      end

      it 'does not save the order' do
        expect { request }.not_to change(HydrogenSupplyOrder, :count)
      end
    end

    context 'when an order exists' do
      before do
        HydrogenSupplyOrder.create!(
          scenario_id: scenario.id,
          order: HydrogenSupplyOrder.default_order.reverse
        )
      end

      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the hydrogen order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HydrogenSupplyOrder.default_order.reverse
        )
      end
    end

    context 'when the existing order contains invalid options' do
      before do
        fo = HydrogenSupplyOrder.new(
          scenario_id: scenario.id,
          order: ['invalid', *HydrogenSupplyOrder.default_order]
        )

        fo.save(validate: false)
      end

      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'omits the invalid options' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HydrogenSupplyOrder.default_order
        )
      end
    end

    context 'when the existing order is missing some options' do
      before do
        HydrogenSupplyOrder.create!(
          scenario_id: scenario.id,
          order: [HydrogenSupplyOrder.default_order.last]
        )
      end

      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'includes the missing options appended to the user choices' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => [
            HydrogenSupplyOrder.default_order.last,
            *HydrogenSupplyOrder.default_order[0..-2]
          ]
        )
      end
    end
  end

  context 'when updating the hydrogen order' do
    shared_examples_for 'a successful hydrogen order update' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the hydrogen order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HydrogenSupplyOrder.default_order.reverse
        )
      end

      it 'does not have any errors' do
        request
        expect(JSON.parse(response.body)).not_to have_key('errors')
      end
    end

    shared_examples_for 'a failed hydrogen order update' do
      it 'is a failed request' do
        request
        expect(response).not_to be_successful
      end

      it 'does not include the hydrogen order data' do
        request
        expect(JSON.parse(response.body)).not_to have_key('order')
      end

      it 'responds with a list of errors' do
        request

        expect(JSON.parse(response.body)).to include(
          'errors' => ['Order contains unknown options: invalid']
        )
      end
    end

    context 'when the hydrogen order does not exist, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }, headers: headers
      end

      include_examples 'a successful hydrogen order update'

      it 'saves the record' do
        expect { request }.to change(HydrogenSupplyOrder, :count).by(1)
      end
    end

    context 'when the scenario does not exist, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }, headers: headers
      end

      before do
        scenario.destroy
      end

      it 'is a failed request' do
        request
        expect(response).to be_not_found
      end

      it 'does not save the record' do
        expect { request }.not_to change(HydrogenSupplyOrder, :count)
      end
    end

    context 'when the hydrogen order does not exist, given invalid data' do
      let(:request) do
        put url, params: { order: %w[invalid] }, headers: headers
      end

      include_examples 'a failed hydrogen order update'

      it 'does not create a new record' do
        expect { request }.not_to change(HydrogenSupplyOrder, :count)
      end
    end

    context 'when the hydrogen order exists, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }, headers: headers
      end

      before do
        HydrogenSupplyOrder.create!(
          scenario_id: scenario.id,
          order: HydrogenSupplyOrder.default_order
        )
      end

      include_examples 'a successful hydrogen order update'

      it 'does not save a new record' do
        expect { request }.not_to change(HydrogenSupplyOrder, :count)
      end
    end

    context 'when the hydrogen order exists, given invalid data' do
      let(:request) do
        put url, params: { order: %w[invalid] }, headers: headers
      end

      before do
        HydrogenSupplyOrder.create!(
          scenario_id: scenario.id,
          order: HydrogenSupplyOrder.default_order
        )
      end

      include_examples 'a failed hydrogen order update'

      it 'does not change the saved record' do
        order = HydrogenSupplyOrder.find_by(scenario_id: scenario.id)
        expect { request }.not_to(change { order.reload.attributes })
      end
    end

    context 'when the request contains an invalid hydrogen_supply_order payload' do
      let(:request) do
        put url, params: { hydrogen_supply_order: 'hi' }, headers: headers
      end

      it 'is a failed request' do
        request
        expect(response).not_to be_successful
      end

      it 'responds with a list of errors' do
        request

        expect(JSON.parse(response.body)).to include(
          'errors' => ['Invalid JSON payload']
        )
      end
    end
  end

  it_behaves_like 'a user sortable with grant-based access', HydrogenSupplyOrder
end
