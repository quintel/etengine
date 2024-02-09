# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 hydrogen orders' do
  let(:valid_options) { HydrogenOrder.default_order }
  let(:scenario) { create(:scenario) }
  let(:url) { api_v3_scenario_hydrogen_order_url(scenario_id: scenario.id) }

  context 'when fetching the hydrogen order' do
    let(:request) { get(url) }

    context 'when no order exists' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the default hydrogen order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HydrogenOrder.default_order
        )
      end

      it 'does not save the order' do
        expect { request }.not_to change(HydrogenOrder, :count)
      end
    end

    context 'when an order exists' do
      before do
        HydrogenOrder.create!(
          scenario_id: scenario.id,
          order: HydrogenOrder.default_order.reverse
        )
      end

      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the hydrogen order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => HydrogenOrder.default_order.reverse
        )
      end
    end

    context 'when the existing order contains invalid options' do
      before do
        fo = HydrogenOrder.new(
          scenario_id: scenario.id,
          order: ['invalid', *HydrogenOrder.default_order]
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
          'order' => HydrogenOrder.default_order
        )
      end
    end

    context 'when the existing order is missing some options' do
      before do
        HydrogenOrder.create!(
          scenario_id: scenario.id,
          order: [HydrogenOrder.default_order.last]
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
            HydrogenOrder.default_order.last,
            *HydrogenOrder.default_order[0..-2]
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
          'order' => HydrogenOrder.default_order.reverse
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

    context 'when the scenario is owned by someone else' do
      before do
        scenario.update!(owner: create(:user))
        put url, params: { order: valid_options.reverse }
      end

      it 'responds with 403 Forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'when the scenario is owned by the current user' do
      before do
        user = create(:user)
        scenario.update!(owner: user)

        put url,
          params: { order: valid_options.reverse },
          headers: access_token_header(user, :write)
      end

      it 'responds with 200 OK' do
        expect(response).to be_successful
      end
    end

    context 'when the hydrogen order does not exist, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }
      end

      include_examples 'a successful hydrogen order update'

      it 'saves the record' do
        expect { request }.to change(HydrogenOrder, :count).by(1)
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
        expect { request }.not_to change(HydrogenOrder, :count)
      end
    end

    context 'when the hydrogen order does not exist, given invalid data' do
      let(:request) do
        put url, params: { order: %w[invalid] }
      end

      include_examples 'a failed hydrogen order update'

      it 'does not create a new record' do
        expect { request }.not_to change(HydrogenOrder, :count)
      end
    end

    context 'when the hydrogen order exists, given valid data' do
      let(:request) do
        put url, params: { order: valid_options.reverse }
      end

      before do
        HydrogenOrder.create!(
          scenario_id: scenario.id,
          order: HydrogenOrder.default_order
        )
      end

      include_examples 'a successful hydrogen order update'

      it 'does not save a new record' do
        expect { request }.not_to change(HydrogenOrder, :count)
      end
    end

    context 'when the hydrogen order exists, given invalid data' do
      let(:request) do
        put url, params: { order: %w[invalid] }
      end

      before do
        HydrogenOrder.create!(
          scenario_id: scenario.id,
          order: HydrogenOrder.default_order
        )
      end

      include_examples 'a failed hydrogen order update'

      it 'does not change the saved record' do
        order = HydrogenOrder.find_by(scenario_id: scenario.id)
        expect { request }.not_to(change { order.reload.attributes })
      end
    end

    context 'when the request contains an invalid hydrogen_order payload' do
      let(:request) do
        put url, params: { hydrogen_order: 'hi' }
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
