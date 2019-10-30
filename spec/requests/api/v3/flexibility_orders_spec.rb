# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 flexibility orders' do
  let(:valid_options) { FlexibilityOrder.default_order }
  let(:scenario) { FactoryBot.create(:scenario) }

  context 'when fetching the flexibility order' do
    let(:request) do
      get get_api_v3_scenario_flexibility_order_url(scenario.id), params: {
        scenario_id: scenario.id,
        flexibility_order: { order: valid_options }
      }
    end

    context 'when no order exists' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the default flexibility order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => FlexibilityOrder.default_order
        )
      end

      it 'does not save the order' do
        expect { request }.not_to change(FlexibilityOrder, :count)
      end
    end

    context 'when an order exists' do
      before do
        FlexibilityOrder.create!(
          scenario_id: scenario.id,
          order: FlexibilityOrder.default_order.reverse
        )
      end

      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the flexibility order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => FlexibilityOrder.default_order.reverse
        )
      end
    end
  end

  context 'when updating the flexibility order' do
    shared_examples_for 'a successful flexibility order update' do
      it 'is a successful request' do
        request
        expect(response).to be_successful
      end

      it 'responds with the flexibility order data' do
        request

        expect(JSON.parse(response.body)).to include(
          'order' => FlexibilityOrder.default_order.reverse
        )
      end

      it 'does not have any errors' do
        request
        expect(JSON.parse(response.body)).not_to have_key('errors')
      end
    end

    shared_examples_for 'a failed flexibility order update' do
      it 'is a failed request' do
        request
        expect(response).not_to be_successful
      end

      it 'does not include the flexibility order data' do
        request
        expect(JSON.parse(response.body)).not_to have_key('order')
      end

      it 'responds with a list of errors' do
        request

        expect(JSON.parse(response.body)).to include(
          'errors' => ['Order contains unknown flexibility options: invalid']
        )
      end
    end

    context 'when the flexibility order does not exist, given valid data' do
      let(:request) do
        post set_api_v3_scenario_flexibility_order_url(scenario.id), params: {
          scenario_id: scenario.id,
          flexibility_order: { order: valid_options.reverse }
        }
      end

      include_examples 'a successful flexibility order update'

      it 'saves the record' do
        expect { request }.to change(FlexibilityOrder, :count).by(1)
      end
    end

    context 'when the scenario does not exist, given valid data' do
      let(:request) do
        post set_api_v3_scenario_flexibility_order_url(scenario.id), params: {
          scenario_id: scenario.id,
          flexibility_order: { order: valid_options.reverse }
        }
      end

      before do
        scenario.destroy
      end

      it 'is a failed request' do
        request
        expect(response).to be_not_found
      end

      it 'does not save the record' do
        expect { request }.not_to change(FlexibilityOrder, :count)
      end
    end

    context 'when the flexibility order does not exist, given invalid data' do
      let(:request) do
        post set_api_v3_scenario_flexibility_order_url(scenario.id), params: {
          scenario_id: scenario.id,
          flexibility_order: { order: %w[invalid] }
        }
      end

      include_examples 'a failed flexibility order update'

      it 'does not create a new record' do
        expect { request }.not_to change(FlexibilityOrder, :count)
      end
    end

    context 'when the flexibility order exists, given valid data' do
      let(:request) do
        post set_api_v3_scenario_flexibility_order_url(scenario.id), params: {
          scenario_id: scenario.id,
          flexibility_order: { order: valid_options.reverse }
        }
      end

      before do
        FlexibilityOrder.create!(
          scenario_id: scenario.id,
          order: FlexibilityOrder.default_order
        )
      end

      include_examples 'a successful flexibility order update'

      it 'does not save a new record' do
        expect { request }.not_to change(FlexibilityOrder, :count)
      end
    end

    context 'when the flexibility order exists, given invalid data' do
      let(:request) do
        post set_api_v3_scenario_flexibility_order_url(scenario.id), params: {
          scenario_id: scenario.id,
          flexibility_order: { order: %w[invalid] }
        }
      end

      before do
        FlexibilityOrder.create!(
          scenario_id: scenario.id,
          order: FlexibilityOrder.default_order
        )
      end

      include_examples 'a failed flexibility order update'

      it 'does not change the saved record' do
        order = FlexibilityOrder.find_by(scenario_id: scenario.id)
        expect { request }.not_to(change { order.reload.attributes })
      end
    end
  end
end
