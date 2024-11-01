# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 flexibility orders' do
  let(:valid_options) { FlexibilityOrder.default_order }
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:url) { api_v3_scenario_flexibility_order_url(scenario_id: scenario.id) }
  let(:user) { create(:user) }

  context 'when fetching the flexibility order' do
    before { get(url, headers: access_token_header(user, :read)) }

    it 'returns a 404' do
      expect(response).to be_not_found
    end

    it 'includes an error message' do
      expect(JSON.parse(response.body)).to include('error' => <<~MSG.squish)
        The flexibility order feature has been removed. Flexible technologies are now sorted
        implicitly by their marginal cost / willingness to pay.
      MSG
    end
  end

  context 'when updating the flexibility order' do
    before do
      put(url, params: { flexibility_order: { order: %w[a b] } }, headers: access_token_header(user, :read))
    end

    it 'returns a 404' do
      expect(response).to be_not_found
    end

    it 'includes an error message' do
      expect(JSON.parse(response.body)).to include('error' => <<~MSG.squish)
        The flexibility order feature has been removed. Flexible technologies are now sorted
        implicitly by their marginal cost / willingness to pay.
      MSG
    end
  end
end
