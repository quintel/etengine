# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 binding scenarios', :etsource_fixture do
  let(:owner) { create(:user) }
  let(:headers) { access_token_header(owner, :delete) }
  let(:json) { JSON.parse(response.body) }

  let(:scenario) { create(:scenario) }
  let(:history) { create(:scenario) }

  def bind(ids, bound, headers: self.headers)
    put('/api/v3/scenarios/bound', params: { ids:, bound: }, headers:, as: :json)
  end

  before do
    scenario.update!(user: owner)
    history.update!(user: owner)
  end

  context 'when the owner binds their scenarios' do
    it 'binds the scenario' do
      expect { bind([scenario.id, history.id], true) }
        .to change { scenario.reload.bound? }.from(false).to(true)
    end

    it 'binds the history' do
      expect { bind([scenario.id, history.id], true) }
        .to change { history.reload.bound? }.from(false).to(true)
    end

    it 'responds 207' do
      bind([scenario.id, history.id], true)

      expect(response).to have_http_status(:multi_status)
    end

    it 'responds with an item per scenario, in request order' do
      bind([history.id, scenario.id], true)

      expect(json['data']).to eq([
        { 'status' => 'ok', 'data' => { 'id' => history.id, 'bound' => true } },
        { 'status' => 'ok', 'data' => { 'id' => scenario.id, 'bound' => true } }
      ])
    end

    it 'counts the outcomes' do
      bind([scenario.id, history.id], true)

      expect(json['meta']).to eq('batch' => { 'succeeded' => 2, 'failed' => 0, 'total' => 2 })
    end
  end

  context 'when the owner unbinds their scenarios' do
    before do
      scenario.update!(bound: true)
      history.update!(bound: true)
    end

    it 'unbinds the scenario' do
      expect { bind([scenario.id, history.id], false) }
        .to change { scenario.reload.bound? }.from(true).to(false)
    end

    it 'unbinds the history' do
      expect { bind([scenario.id, history.id], false) }
        .to change { history.reload.bound? }.from(true).to(false)
    end
  end

  context 'when the owner binds an already bound scenario' do
    before { scenario.update!(bound: true) }

    it 'does not change the flag' do
      expect { bind([scenario.id], true) }
        .not_to change { scenario.reload.bound? }.from(true)
    end

    it 'responds 207' do
      bind([scenario.id], true)

      expect(response).to have_http_status(:multi_status)
    end
  end

  context 'when some scenarios belong to another user' do
    let(:other_user) { create(:user) }
    let(:public_other) { create(:scenario) }
    let(:private_other) { create(:scenario) }

    before do
      public_other.update!(user: other_user)
      private_other.update!(user: other_user)
      private_other.update!(private: true)

      bind([scenario.id, public_other.id, private_other.id, -1], true)
    end

    it 'binds the owned scenario' do
      expect(scenario.reload).to be_bound
    end

    it 'does not bind the public scenario' do
      expect(public_other.reload).not_to be_bound
    end

    it 'does not bind the private scenario' do
      expect(private_other.reload).not_to be_bound
    end

    it 'reports the public scenario as forbidden' do
      expect(json['data'][1]).to include(
        'status' => 'error', 'code' => 'forbidden', 'source' => { 'pointer' => '/ids/1' }
      )
    end

    it 'reports the private scenario as not found' do
      expect(json['data'][2]).to include('status' => 'error', 'code' => 'not_found')
    end

    it 'reports a missing scenario as not found' do
      expect(json['data'][3]).to include('status' => 'error', 'code' => 'not_found')
    end

    it 'counts the outcomes' do
      expect(json['meta']).to eq('batch' => { 'succeeded' => 1, 'failed' => 3, 'total' => 4 })
    end
  end

  context 'when a collaborator binds a scenario' do
    let(:collaborator) { create(:user) }

    before do
      create(
        :scenario_user,
        scenario:,
        user: collaborator,
        role_id: User::ROLES.key(:scenario_collaborator)
      )
    end

    it 'does not change the flag' do
      expect { bind([scenario.id], true, headers: access_token_header(collaborator, :delete)) }
        .not_to change { scenario.reload.bound? }.from(false)
    end

    it 'reports the scenario as forbidden' do
      bind([scenario.id], true, headers: access_token_header(collaborator, :delete))

      expect(json['data'].first).to include('code' => 'forbidden')
    end
  end

  context 'when the owner binds with only the write scope' do
    it 'does not change the flag' do
      expect { bind([scenario.id], true, headers: access_token_header(owner, :write)) }
        .not_to change { scenario.reload.bound? }.from(false)
    end
  end

  context 'when binding an unowned scenario as a guest' do
    let(:unowned) { create(:scenario) }

    it 'does not change the flag' do
      expect { bind([unowned.id], true, headers: {}) }
        .not_to change { unowned.reload.bound? }.from(false)
    end

    it 'reports the scenario as forbidden' do
      bind([unowned.id], true, headers: {})

      expect(json['data'].first).to include('code' => 'forbidden')
    end
  end

  context 'with an invalid bound value' do
    it 'does not change the flag' do
      expect { bind([scenario.id], 'yes') }
        .not_to change { scenario.reload.bound? }.from(false)
    end

    it 'responds 400' do
      bind([scenario.id], 'yes')

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'with more than the maximum number of ids' do
    let(:ids) { [scenario.id] + Array.new(Api::V3::ScenariosController::MAX_BOUND_IDS, -1) }

    it 'does not change the flag' do
      expect { bind(ids, true) }
        .not_to change { scenario.reload.bound? }.from(false)
    end

    it 'responds 400' do
      bind(ids, true)

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'with the maximum number of ids' do
    let(:ids) { [scenario.id] + Array.new(Api::V3::ScenariosController::MAX_BOUND_IDS - 1, -1) }

    it 'responds 207' do
      bind(ids, true)

      expect(response).to have_http_status(:multi_status)
    end
  end

  context 'without ids' do
    it 'responds 400' do
      put('/api/v3/scenarios/bound', params: { bound: true }, headers:, as: :json)

      expect(response).to have_http_status(:bad_request)
    end
  end
end
