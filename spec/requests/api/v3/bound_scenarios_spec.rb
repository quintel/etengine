# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 binding scenarios', :etsource_fixture do
  let(:myetm_headers) do
    access_token_header(create(:user, admin: true), 'public scenarios:read scenarios:write scenarios:bind')
  end
  let(:json) { response.parsed_body }

  let(:scenario) { create(:scenario) }
  let(:history) { create(:scenario) }

  def bind(ids, bound, headers: myetm_headers)
    put('/api/v3/scenarios/bind', params: { ids:, bound: }, headers:, as: :json)
  end

  context 'with the bind scope, as an admin' do
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

    it 'stops keeping every unbound scenario compatible' do
      scenario.update!(bound: true, keep_compatible: true)
      history.update!(bound: true, keep_compatible: true)
      bind([scenario.id, history.id], false)

      expect([scenario.reload, history.reload]).to all(satisfy { |s| !s.keep_compatible? })
    end

    it 'leaves keep_compatible alone when binding' do
      scenario.update!(keep_compatible: true)
      history.update!(keep_compatible: false)
      bind([scenario.id, history.id], true)

      expect([scenario.reload, history.reload].map(&:keep_compatible?)).to eq([true, false])
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

  context 'when binding for a user' do
    let(:user) { create(:user) }

    def bind_as_user(ids, bound, scenario_access: nil)
      scopes = 'public scenarios:read scenarios:write scenarios:bind'
      bind(ids, bound, headers: access_token_header(user, scopes, scenario_access:))
    end

    def someone_elses_session
      create(:scenario, creator_id: create(:user).id, private: true)
    end

    it 'refuses a scenario the user cannot update' do
      session = someone_elses_session
      bind_as_user([session.id], true)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'lists the refused scenarios' do
      session = someone_elses_session
      bind_as_user([session.id], true)

      expect(json).to eq('refused' => [session.id])
    end

    it 'leaves a refused scenario unbound' do
      session = someone_elses_session
      bind_as_user([session.id], true)

      expect(session.reload).not_to be_bound
    end

    it 'refuses a scenario that is already bound' do
      own_session = create(:scenario, creator_id: user.id, bound: true)
      bind_as_user([own_session.id], true)

      expect(json).to eq('refused' => [own_session.id])
    end

    it 'refuses an ID that matches no scenario' do
      bind_as_user([-1], true)

      expect(json).to eq('refused' => [-1])
    end

    it 'binds a scenario the user created' do
      own_session = create(:scenario, creator_id: user.id, private: true)
      bind_as_user([own_session.id], true)

      expect(own_session.reload).to be_bound
    end

    it 'binds nothing when any scenario is refused' do
      own_session = create(:scenario, creator_id: user.id)
      bind_as_user([own_session.id, someone_elses_session.id], true)

      expect(own_session.reload).not_to be_bound
    end

    it 'unbinds a scenario the user cannot update' do
      session = someone_elses_session
      session.update!(bound: true)
      bind_as_user([session.id], false)

      expect(session.reload).not_to be_bound
    end

    it 'binds a scenario created by someone else the token grants write access to' do
      session = someone_elses_session
      bind_as_user([session.id], true, scenario_access: scenario_grant(write: [session.id]))

      expect(session.reload).to be_bound
    end

    it 'refuses a scenario created by someone else the token grants read access to' do
      session = someone_elses_session
      bind_as_user([session.id], true, scenario_access: scenario_grant(read: [session.id]))

      expect(json).to eq('refused' => [session.id])
    end

    it 'refuses a bound scenario the token grants write access to' do
      session = create(:scenario, bound: true, private: true)
      bind_as_user([session.id], true, scenario_access: scenario_grant(write: [session.id]))

      expect(json).to eq('refused' => [session.id])
    end
  end

  context 'without the bind scope' do
    before { scenario.update!(creator_id: owner.id) }

    let(:owner) { create(:user) }

    it 'refuses the owner' do
      bind([scenario.id], true, headers: access_token_header(owner, :delete))

      expect(scenario.reload).not_to be_bound
    end

    it 'refuses an admin' do
      bind([scenario.id], true, headers: access_token_header(create(:admin), :delete))

      expect(scenario.reload).not_to be_bound
    end

    it 'refuses a guest' do
      bind([scenario.id], true, headers: {})

      expect(scenario.reload).not_to be_bound
    end
  end
end
