# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 heat network orders' do
  let(:valid_options) { HeatNetworkOrder.default_order }
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:url) { api_v3_scenario_heat_network_order_url(scenario_id: scenario.id, subtype: :ht) }

  context 'when fetching the heat network order' do
    let(:request) { get(url) }

    context 'when no order exists' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the default heat network order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HeatNetworkOrder.default_order
        )
      end

      it 'does not save the order' do
        expect { request }.not_to change(HeatNetworkOrder, :count)
      end
    end

    context 'when an order exists' do
      before do
        HeatNetworkOrder.create!(
          scenario_id: scenario.id,
          order: HeatNetworkOrder.default_order.reverse,
          temperature: :ht
        )
      end

      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the heat network order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HeatNetworkOrder.default_order.reverse
        )
      end
    end

    context 'when the existing order contains invalid options' do
      before do
        fo = HeatNetworkOrder.new(
          scenario_id: scenario.id,
          order: ['invalid', *HeatNetworkOrder.default_order]
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
          'order' => HeatNetworkOrder.default_order
        )
      end
    end

    context 'when the existing order is missing some options' do
      before do
        HeatNetworkOrder.create!(
          scenario_id: scenario.id,
          order: [HeatNetworkOrder.default_order.last],
          temperature: :ht
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
            HeatNetworkOrder.default_order.last,
            *HeatNetworkOrder.default_order[0..-2]
          ]
        )
      end
    end
  end

  context 'when updating the heat network order' do
    shared_examples_for 'a successful heat network order update' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the heat network order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HeatNetworkOrder.default_order.reverse
        )
      end

      it 'does not have any errors' do
        request
        expect(JSON.parse(response.body)).not_to have_key('errors')
      end
    end

    shared_examples_for 'a failed heat network order update' do
      it 'is a failed request' do
        request
        expect(response).not_to be_successful
      end

      it 'does not include the heat network order data' do
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

    context 'when the scenario is owned by someone else' do
      before do
        scenario.remove_all_users
        scenario.user = create(:user)
        put url, params: { order: valid_options.reverse }
      end

      it 'responds with 403 Forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'when the scenario is owned by the current user' do
      before do
        user = create(:user)
        scenario.remove_all_users
        scenario.user = user

        put url,
          params: { order: valid_options.reverse },
          headers: access_token_header(user, :write)
      end

      it 'responds with 200 OK' do
        expect(response).to be_successful
      end
    end

    context 'when the heat network order does not exist, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }
      end

      include_examples 'a successful heat network order update'

      it 'saves the record' do
        expect { request }.to change(HeatNetworkOrder, :count).by(1)
      end
    end

    # Backwards compatibility.
    context 'when the heat network order does not exist, given valid data as a sub-key' do
      let(:request) do
        put url, params: {
          heat_network_order: { order: valid_options.reverse }
        }
      end

      include_examples 'a successful heat network order update'

      it 'saves the record' do
        expect { request }.to change(HeatNetworkOrder, :count).by(1)
      end
    end

    context 'when the scenario does not exist, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }
      end

      before do
        scenario.destroy
      end

      it 'is a failed request' do
        request
        expect(response).to be_not_found
      end

      it 'does not save the record' do
        expect { request }.not_to change(HeatNetworkOrder, :count)
      end
    end

    context 'when the heat network order does not exist, given invalid data' do
      let(:request) do
        put url, params: { order: %w[invalid] }
      end

      include_examples 'a failed heat network order update'

      it 'does not create a new record' do
        expect { request }.not_to change(HeatNetworkOrder, :count)
      end
    end

    context 'when the heat network order exists, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }
      end

      before do
        HeatNetworkOrder.create!(
          scenario_id: scenario.id,
          order: HeatNetworkOrder.default_order,
          temperature: :ht
        )
      end

      include_examples 'a successful heat network order update'

      it 'does not save a new record' do
        expect { request }.not_to change(HeatNetworkOrder, :count)
      end
    end

    # Supported for backwards compatibility.
    context 'when the heat network order exists, given valid data as a sub-key' do
      let(:request) do
        put url, params: {
          heat_network_order: { order: valid_options.reverse }
        }
      end

      before do
        HeatNetworkOrder.create!(
          scenario_id: scenario.id,
          order: HeatNetworkOrder.default_order,
          temperature: :ht
        )
      end

      include_examples 'a successful heat network order update'

      it 'does not save a new record' do
        expect { request }.not_to change(HeatNetworkOrder, :count)
      end
    end

    context 'when the heat network order exists, given invalid data' do
      let(:request) do
        put url, params: { order: %w[invalid] }
      end

      before do
        HeatNetworkOrder.create!(
          scenario_id: scenario.id,
          order: HeatNetworkOrder.default_order
        )
      end

      include_examples 'a failed heat network order update'

      it 'does not change the saved record' do
        order = HeatNetworkOrder.find_by(scenario_id: scenario.id)
        expect { request }.not_to(change { order.reload.attributes })
      end
    end

    context 'when the request contains an invalid heat_network_order payload' do
      let(:request) do
        put url, params: { heat_network_order: 'hi' }
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
end
