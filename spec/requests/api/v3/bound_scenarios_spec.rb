# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 binding scenarios', :etsource_fixture do
  let(:myetm_headers) { access_token_header(create(:user), 'public scenarios:bind') }
  let(:json) { response.parsed_body }

  let(:scenario) { create(:scenario) }
  let(:history) { create(:scenario) }

  def bind(ids, bound, headers: myetm_headers)
    put('/api/v3/scenarios/bind', params: { ids:, bound: }, headers:, as: :json)
  end

  context 'with the bind scope' do
    it 'binds every scenario' do
      bind([scenario.id, history.id], true)

      expect([scenario.reload, history.reload]).to all(be_bound)
    end

    it 'unbinds every scenario' do
      scenario.update!(bound: true)
      history.update!(bound: true)
      bind([scenario.id, history.id], false)

      expect([scenario.reload, history.reload]).to all(satisfy { |s| !s.bound? })
    end

    it 'leaves an already bound scenario bound' do
      scenario.update!(bound: true)
      bind([scenario.id], true)

      expect(scenario.reload).to be_bound
    end

    it 'reports IDs that match no scenario' do
      bind([scenario.id, -1], true)

      expect(json).to eq('missing' => [-1])
    end

    it 'refuses a bound value that is not a boolean' do
      expect { bind([scenario.id], 'yes') }.not_to(change { scenario.reload.bound? })
    end

    it 'refuses a request without ids' do
      put('/api/v3/scenarios/bind', params: { bound: true }, headers: myetm_headers, as: :json)

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'without the bind scope' do
    before { scenario.update!(user: owner) }

    let(:owner) { create(:user) }

    it 'refuses the owner' do
      bind([scenario.id], true, headers: access_token_header(owner, :delete))

      expect(scenario.reload).not_to be_bound
    end

    it 'refuses an admin' do
      bind([scenario.id], true, headers: access_token_header(create(:admin), :delete))

      expect(scenario.reload).not_to be_bound
    end

    it 'refuses a scope whose name only starts with the bind scope' do
      headers = access_token_header(create(:user), 'public scenarios:binder')
      bind([scenario.id], true, headers:)

      expect(scenario.reload).not_to be_bound
    end

    it 'refuses a guest' do
      bind([scenario.id], true, headers: {})

      expect(scenario.reload).not_to be_bound
    end
  end
end
